-- ============================================================
-- procedures.sql — Stored Procedures
--
-- PROCEDURES IN THIS FILE:
--   1. AllocateSeats()
--        Runs the full merit-based seat allocation engine for
--        a given counselling round.
--
--   2. UpdateSeatAvailability(p_program_id)
--        Re-syncs Filled_Seats in SEAT_MATRIX by counting
--        actual non-withdrawn allocations (reconciliation tool).
--
--   3. GenerateAllocationReport()
--        Emits three result sets:
--          (a) Round-level summary
--          (b) Program-wise allocation breakdown
--          (c) Category-wise seat usage
--
-- SCHEMA NOTES THAT INFLUENCE THIS CODE:
--   • SEAT_MATRIX.Available_Seats is a GENERATED ALWAYS column
--     (Total_Seats – Filled_Seats). It CANNOT be updated directly.
--     Only Filled_Seats is written to.
--   • Triggers trg_increment_filled_seats_after_allocation and
--     trg_decrement_filled_seats_after_withdrawal already keep
--     Filled_Seats accurate on INSERT / UPDATE of SEAT_ALLOCATION.
--     AllocateSeats therefore does NOT touch SEAT_MATRIX manually;
--     it relies on those triggers.
--   • Trigger trg_handle_upgrade_on_new_allocation auto-withdraws
--     prior-round allocations when a new one is inserted.
--   • Trigger trg_sync_choice_status_after_allocation marks the
--     allocated choice as 'Allocated' and resets others to 'Active'.
-- ============================================================

DELIMITER $$

-- ============================================================
-- PROCEDURE 1 : AllocateSeats
-- ============================================================
-- PURPOSE
--   Implements the merit-cum-preference seat allocation algorithm:
--     1. Iterate students in ascending JEE rank order (rank 1 = best).
--     2. Skip students who already hold a non-withdrawn allocation
--        in this round (idempotent re-runs are safe).
--     3. For each eligible student, find the highest-preference
--        choice that has at least one Available_Seat in the
--        student's own category.
--     4. Insert a row into SEAT_ALLOCATION.
--        (Triggers handle Filled_Seats, choice status sync, and
--         prior-round withdrawal automatically.)
--     5. Wrap every student's allocation in its own SAVEPOINT so
--        a single failure never rolls back other students.
-- ============================================================
DROP PROCEDURE IF EXISTS AllocateSeats$$

CREATE PROCEDURE AllocateSeats()
BEGIN
    -- --------------------------------------------------------
    -- Local variables
    -- --------------------------------------------------------
    DECLARE v_done          INT     DEFAULT 0;   -- cursor EOF flag
    DECLARE v_student_id    INT;
    DECLARE v_category      ENUM('General','OBC','SC','ST','EWS');
    DECLARE v_seat_id       INT     DEFAULT NULL;
    DECLARE v_already_alloc INT     DEFAULT 0;
    DECLARE v_total_alloc   INT     DEFAULT 0;
    DECLARE v_err_msg       TEXT;

    -- --------------------------------------------------------
    -- Cursor: all students ordered by JEE rank (best rank first)
    -- --------------------------------------------------------
    DECLARE cur_students CURSOR FOR
        SELECT Student_ID, Category
        FROM   STUDENT
        ORDER  BY JEE_Rank ASC;

    -- Standard NOT FOUND handler — sets v_done when cursor is exhausted
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- Catch any SQL exception, capture the message, and continue
    -- (per-student error must not abort the entire round)
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_err_msg = MESSAGE_TEXT;
        ROLLBACK TO SAVEPOINT sp_student;
        INSERT INTO ALLOCATION_AUDIT (
            Allocation_ID, Student_ID, Seat_ID,
            Old_Status, New_Status, Action_Type, Changed_At
        ) VALUES (
            NULL, v_student_id, NULL,
            NULL, 'Rejected',
            'INSERT', NOW()
        );
    END;


    -- --------------------------------------------------------
    -- Begin the outer transaction for the whole round
    -- --------------------------------------------------------
    START TRANSACTION;

    OPEN cur_students;

    student_loop: LOOP
        FETCH cur_students INTO v_student_id, v_category;

        -- Exit when cursor is exhausted
        IF v_done = 1 THEN
            LEAVE student_loop;
        END IF;

        -- Reset per-iteration variables
        SET v_seat_id       = NULL;
        SET v_already_alloc = 0;
        SAVEPOINT sp_student;

        -- -------------------------------------------------------
        -- Guard: skip if student already has a live allocation
        --        in this round (supports safe re-runs).
        -- -------------------------------------------------------
        SELECT COUNT(*)
        INTO   v_already_alloc
        FROM   SEAT_ALLOCATION
        WHERE  Student_ID        = v_student_id
          AND  Allocation_Status <> 'Withdrawn';

        IF v_already_alloc > 0 THEN
            ITERATE student_loop;
        END IF;

        -- -------------------------------------------------------
        -- Core allocation query:
        --   Join CHOICE → SEAT_MATRIX on Program_ID,
        --   filter by student's category and seat availability,
        --   order by Preference_Order so the top unfilled choice wins.
        --   LIMIT 1 returns the single best match.
        -- -------------------------------------------------------
        SELECT SM.Seat_ID
        INTO   v_seat_id
        FROM   CHOICE      C
        JOIN   SEAT_MATRIX SM
               ON  SM.Program_ID = C.Program_ID
               AND SM.Category   = v_category     -- match student's category
        WHERE  C.Student_ID  = v_student_id
          AND  C.Status      = 'Active'            -- ignore already-allocated/withdrawn choices
          AND  SM.Available_Seats > 0              -- seats must exist (generated column)
        ORDER  BY C.Preference_Order ASC
        LIMIT  1;

        

        -- -------------------------------------------------------
        -- If a seat was found, insert the allocation inside its
        -- own SAVEPOINT so failures are isolated.
        -- -------------------------------------------------------
        IF v_seat_id IS NOT NULL THEN

            INSERT INTO SEAT_ALLOCATION (
                Student_ID,
                Seat_ID,
                Allocation_Status,
                Allocation_Date,
                Admission_Status
            ) VALUES (
                v_student_id,
                v_seat_id,
                'Allocated',
                NOW(),
                'Pending'
            );

            -- Triggers fire here automatically:
            --   trg_check_seats_before_allocation   → final seat / duplicate guard
            --   trg_increment_filled_seats           → Filled_Seats + 1
            --   trg_sync_choice_status               → marks the choice 'Allocated'
            --   trg_log_allocation_insert            → writes audit row

            SET v_total_alloc = v_total_alloc + 1;

        END IF;
        RELEASE SAVEPOINT sp_student;
        -- Students with no available seat in any active choice are
        -- simply skipped; they remain unallocated for this round.

    END LOOP student_loop;

    CLOSE cur_students;

    -- Commit all successful allocations atomically
    COMMIT;

    -- --------------------------------------------------------
    -- Return a brief summary to the caller
    -- --------------------------------------------------------
    SELECT
        v_total_alloc          AS New_Allocations_This_Run,
        NOW()                  AS Completed_At;

END$$


-- ============================================================
-- PROCEDURE 2 : UpdateSeatAvailability
-- ============================================================
-- PURPOSE
--   Reconciliation utility. Re-counts non-withdrawn allocations
--   per SEAT_MATRIX row and writes the result into Filled_Seats.
--   Use this after any bulk import, manual data fix, or if you
--   suspect the triggers drifted (e.g. direct SQL edits bypassed
--   them during testing).
--
--   Available_Seats is a GENERATED column and auto-updates as
--   soon as Filled_Seats changes — no extra step needed.
--
-- PARAMETERS
--   p_program_id  INT   — Pass a specific Program_ID to refresh
--                         only its seat rows, or NULL to refresh
--                         the entire SEAT_MATRIX table.
-- ============================================================
DROP PROCEDURE IF EXISTS UpdateSeatAvailability$$

CREATE PROCEDURE UpdateSeatAvailability(IN p_program_id INT)
BEGIN
    DECLARE v_exists INT DEFAULT 0;

    -- --------------------------------------------------------
    -- Validate: if provided, the program must actually exist
    -- --------------------------------------------------------
    IF p_program_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_exists
        FROM PROGRAM
        WHERE Program_ID = p_program_id;

        IF v_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'UpdateSeatAvailability: Program_ID not found.';
        END IF;
    END IF;

    -- --------------------------------------------------------
    -- Bulk UPDATE using a correlated subquery.
    --
    -- For every SEAT_MATRIX row in scope, Filled_Seats is set
    -- to the count of SEAT_ALLOCATION rows whose status is
    -- NOT 'Withdrawn' — the only states that occupy a physical seat.
    -- --------------------------------------------------------
    START TRANSACTION;

    UPDATE SEAT_MATRIX SM
    SET    SM.Filled_Seats = (
               SELECT COUNT(*)
               FROM   SEAT_ALLOCATION SA
               WHERE  SA.Seat_ID           = SM.Seat_ID
                 AND  SA.Allocation_Status = 'Allocated'
           )
    WHERE  (p_program_id IS NULL OR SM.Program_ID = p_program_id);

    COMMIT;

    -- --------------------------------------------------------
    -- Return the refreshed rows so the caller can verify
    -- --------------------------------------------------------
    SELECT
        SM.Seat_ID,
        P.Program_Name,
        SM.Category,
        SM.Total_Seats,
        SM.Filled_Seats,
        SM.Available_Seats,         -- generated column, reflects update immediately
        SM.Cutoff_Rank
    FROM  SEAT_MATRIX SM
    JOIN  PROGRAM     P  ON P.Program_ID = SM.Program_ID
    WHERE (p_program_id IS NULL OR SM.Program_ID = p_program_id)
    ORDER  BY SM.Seat_ID;

END$$


-- ============================================================
-- PROCEDURE 3 : GenerateAllocationReport
-- ============================================================
-- PURPOSE
--   Produces three result sets for the given counselling round
--   (or ALL rounds when NULL is passed):
--
--   Result Set 1 — Round Summary
--     Overall allocation counts and admission status breakdown.
--
--   Result Set 2 — Program-wise Breakdown
--     Per-program: total allocations, withdrawals, confirmations.
--     Includes current seat fill percentage.
--
--   Result Set 3 — Category-wise Seat Usage
--     For every (Program, Category) combination: seats total,
--     filled, available, and utilisation percentage.
-- ============================================================
DROP PROCEDURE IF EXISTS GenerateAllocationReport$$

CREATE PROCEDURE GenerateAllocationReport()
BEGIN

    -- --------------------------------------------------------
    -- Result Set 1 : Overall summary
    -- --------------------------------------------------------
    SELECT
        COUNT(*)                                AS Total_Allocations,
        SUM(Allocation_Status = 'Allocated')    AS Status_Allocated,
        SUM(Allocation_Status = 'Withdrawn')    AS Status_Withdrawn,
        SUM(Allocation_Status = 'Rejected')     AS Status_Rejected,
        SUM(Admission_Status  = 'Confirmed')    AS Admissions_Confirmed,
        SUM(Admission_Status  = 'Pending')      AS Admissions_Pending,
        SUM(Admission_Status  = 'Cancelled')    AS Admissions_Cancelled
    FROM SEAT_ALLOCATION;

    -- --------------------------------------------------------
    -- Result Set 2 : Program-wise allocation breakdown
    -- --------------------------------------------------------
    SELECT
        I.Institute_Name,
        P.Program_Name,
        P.Degree,
        COUNT(SA.Allocation_ID)                                   AS Total_Allocated,
        SUM(SA.Allocation_Status = 'Withdrawn')                   AS Withdrawn,
        SUM(SA.Admission_Status  = 'Confirmed')                   AS Confirmed,
        MAX(SM_agg.Total_Seats)                                   AS Total_Seats,
        MAX(SM_agg.Filled_Seats)                                   AS Filled_Seats,
        ROUND(
            100.0 * MAX(SM_agg.Filled_Seats)
                  / NULLIF(MAX(SM_agg.Total_Seats), 0),
            2
        )                                                         AS Fill_Pct
    FROM   SEAT_ALLOCATION SA
    JOIN   SEAT_MATRIX     SM    ON SM.Seat_ID     = SA.Seat_ID
    JOIN   PROGRAM         P     ON P.Program_ID   = SM.Program_ID
    JOIN   INSTITUTE       I     ON I.Institute_ID = P.Institute_ID
    JOIN  (
              SELECT Program_ID,
                     SUM(Total_Seats)  AS Total_Seats,
                     SUM(Filled_Seats) AS Filled_Seats
              FROM   SEAT_MATRIX
              GROUP  BY Program_ID
          ) SM_agg ON SM_agg.Program_ID = P.Program_ID
    GROUP  BY I.Institute_Name, P.Program_Name, P.Degree
    ORDER  BY I.Institute_Name, P.Program_Name;

    -- --------------------------------------------------------
    -- Result Set 3 : Category-wise seat usage
    -- --------------------------------------------------------
    SELECT
        I.Institute_Name,
        P.Program_Name,
        SM.Category,
        SM.Total_Seats,
        SM.Filled_Seats,
        SM.Available_Seats,
        SM.Cutoff_Rank,
        ROUND(
            100.0 * SM.Filled_Seats / NULLIF(SM.Total_Seats, 0),
            2
        )                                 AS Utilisation_Pct,
        SM.Filled_Seats                   AS Active_Alloc_Count
    FROM   SEAT_MATRIX SM
    JOIN   PROGRAM     P  ON P.Program_ID   = SM.Program_ID
    JOIN   INSTITUTE   I  ON I.Institute_ID = P.Institute_ID
    ORDER  BY I.Institute_Name, P.Program_Name, SM.Category;

END$$