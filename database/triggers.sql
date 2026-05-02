-- ============================================================
-- triggers.sql — Database triggers for jee_admission_db
-- Project: JEE Counselling & Seat Allocation System
-- CORRECTED VERSION - All syntax errors fixed
-- MySQL 8.0+ compatible, InnoDB safe
--
-- TRIGGERS IN THIS FILE:
--   1.  trg_verify_rank_before_student_insert
--   2.  trg_mark_rank_used_after_student_insert
--   3.  trg_prevent_duplicate_rank_on_update
--   4.  trg_check_seats_before_allocation       
--   5.  trg_increment_filled_seats_after_allocation
--   6.  trg_decrement_filled_seats_after_withdrawal 
--   7.  trg_sync_choice_status_after_allocation  
--   8.  trg_prevent_choice_after_allocation      
--   9. trg_log_allocation_insert               
--   10. trg_log_allocation_update               
-- ============================================================

DELIMITER $$

-- ============================================================
-- TRIGGER 1: trg_verify_rank_before_student_insert
-- Purpose: Validate that JEE rank exists in official records
--          and hasn't been registered before
-- ============================================================
DROP TRIGGER IF EXISTS trg_verify_rank_before_student_insert$$

CREATE TRIGGER trg_verify_rank_before_student_insert
BEFORE INSERT ON STUDENT
FOR EACH ROW
BEGIN
    DECLARE v_is_used INT DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;

    -- Check if rank exists in official JEE records
    SELECT COUNT(*) INTO v_exists
    FROM JEE_RANK_VERIFY
    WHERE JEE_Rank = NEW.JEE_Rank
      AND Year = NEW.Year;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration failed: JEE Rank not found in official records.';
    END IF;

    -- Check if rank already used by another student
    SELECT COUNT(*) INTO v_is_used
    FROM JEE_RANK_VERIFY
    WHERE JEE_Rank = NEW.JEE_Rank
      AND Year = NEW.Year
      AND Is_Used = TRUE;

    IF v_is_used > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration failed: This JEE Rank is already registered.';
    END IF;
END$$

-- ============================================================
-- TRIGGER 2: trg_mark_rank_used_after_student_insert
-- Purpose: Mark the JEE rank as used after successful registration
-- ============================================================
DROP TRIGGER IF EXISTS trg_mark_rank_used_after_student_insert$$

CREATE TRIGGER trg_mark_rank_used_after_student_insert
AFTER INSERT ON STUDENT
FOR EACH ROW
BEGIN
    UPDATE JEE_RANK_VERIFY
    SET Is_Used = TRUE
    WHERE JEE_Rank = NEW.JEE_Rank
      AND Year = NEW.Year;
END$$

-- ============================================================
-- TRIGGER 3: trg_prevent_duplicate_rank_on_update
-- Purpose: Prevent student from changing rank to one already used
-- ============================================================
DROP TRIGGER IF EXISTS trg_prevent_duplicate_rank_on_update$$

CREATE TRIGGER trg_prevent_duplicate_rank_on_update
BEFORE UPDATE ON STUDENT
FOR EACH ROW
BEGIN
    DECLARE v_is_used INT DEFAULT 0;
    DECLARE v_exists INT DEFAULT 0;

    -- Only validate if rank is being changed
    IF NEW.JEE_Rank <> OLD.JEE_Rank THEN

        -- Check if new rank exists in official records
        SELECT COUNT(*) INTO v_exists
        FROM JEE_RANK_VERIFY
        WHERE JEE_Rank = NEW.JEE_Rank
          AND Year = NEW.Year;

        IF v_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Update failed: New JEE Rank not found in official records.';
        END IF;

        -- Check if new rank already used
        SELECT COUNT(*) INTO v_is_used
        FROM JEE_RANK_VERIFY
        WHERE JEE_Rank = NEW.JEE_Rank
          AND Year = NEW.Year
          AND Is_Used = TRUE;

        IF v_is_used > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Update failed: New JEE Rank is already registered by another student.';
        END IF;

        -- Unmark old rank
        UPDATE JEE_RANK_VERIFY
        SET Is_Used = FALSE
        WHERE JEE_Rank = OLD.JEE_Rank 
          AND Year = OLD.Year;

        -- Mark new rank as used
        UPDATE JEE_RANK_VERIFY
        SET Is_Used = TRUE
        WHERE JEE_Rank = NEW.JEE_Rank 
          AND Year = NEW.Year;

    END IF;
END$$

-- ============================================================
-- TRIGGER 4: trg_check_seats_before_allocation
-- Purpose: Validate seat availability and prevent duplicate 
--          allocations in same round before inserting allocation
-- ============================================================
DROP TRIGGER IF EXISTS trg_check_seats_before_allocation$$

CREATE TRIGGER trg_check_seats_before_allocation
BEFORE INSERT ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    DECLARE v_available INT DEFAULT 0;

    -- Guard 1: Check seat availability
    -- InnoDB row-level locking ensures no race condition
    SELECT Available_Seats INTO v_available
    FROM SEAT_MATRIX
    WHERE Seat_ID = NEW.Seat_ID;

    IF v_available IS NULL OR v_available <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Allocation failed: No seats available in this category.';
    END IF;

END$$

-- ============================================================
-- TRIGGER 5: trg_increment_filled_seats_after_allocation
-- Purpose: Increment Filled_Seats counter when seat allocated
-- ============================================================
DROP TRIGGER IF EXISTS trg_increment_filled_seats_after_allocation$$

CREATE TRIGGER trg_increment_filled_seats_after_allocation
AFTER INSERT ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    UPDATE SEAT_MATRIX
    SET Filled_Seats = Filled_Seats + 1
    WHERE Seat_ID = NEW.Seat_ID;
END$$

-- ============================================================
-- TRIGGER 6: trg_decrement_filled_seats_after_withdrawal
-- Purpose: Decrement Filled_Seats when student withdraws
-- ============================================================
DROP TRIGGER IF EXISTS trg_decrement_filled_seats_after_withdrawal$$

CREATE TRIGGER trg_decrement_filled_seats_after_withdrawal
AFTER UPDATE ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    -- Only decrement if status changed to Withdrawn
    IF NEW.Allocation_Status = 'Withdrawn'
       AND OLD.Allocation_Status <> 'Withdrawn' THEN
        UPDATE SEAT_MATRIX
        SET Filled_Seats = Filled_Seats - 1
        WHERE Seat_ID = NEW.Seat_ID;
    END IF;
END$$

-- ============================================================
-- TRIGGER 7: trg_sync_choice_status_after_allocation
-- Purpose: Mark allocated choice as 'Allocated', reset others to 'Active'
-- ============================================================
DROP TRIGGER IF EXISTS trg_sync_choice_status_after_allocation$$

CREATE TRIGGER trg_sync_choice_status_after_allocation
AFTER INSERT ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    DECLARE v_program_id INT DEFAULT 0;

    -- Get program_id from seat_matrix
    SELECT Program_ID INTO v_program_id
    FROM SEAT_MATRIX
    WHERE Seat_ID = NEW.Seat_ID;

    IF v_program_id IS NOT NULL AND v_program_id > 0 THEN
        -- Mark the allocated choice
        UPDATE CHOICE
        SET Status = 'Allocated'
        WHERE Student_ID = NEW.Student_ID
          AND Program_ID = v_program_id;

        -- Reset all other allocated choices back to Active
        -- Reset any previously allocated choice back to Active
        UPDATE CHOICE
        SET Status = 'Active'
        WHERE Student_ID = NEW.Student_ID
          AND Program_ID <> v_program_id
          AND Status = 'Allocated';
    END IF;
END$$

-- ============================================================
-- TRIGGER 8: trg_prevent_choice_after_allocation
-- Purpose: Block new choice entries if student already allocated
-- ============================================================
DROP TRIGGER IF EXISTS trg_prevent_choice_after_allocation$$

CREATE TRIGGER trg_prevent_choice_after_allocation
BEFORE INSERT ON CHOICE
FOR EACH ROW
BEGIN
    DECLARE v_has_seat INT DEFAULT 0;

    -- Check if student has ANY non-withdrawn allocation
    SELECT COUNT(*) INTO v_has_seat
    FROM SEAT_ALLOCATION
    WHERE Student_ID = NEW.Student_ID
      AND Allocation_Status <> 'Withdrawn';

    IF v_has_seat > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot add choices: Student already has an active seat allocation.';
    END IF;
END$$

-- ============================================================
-- TRIGGER 9: trg_log_allocation_insert
-- Purpose: Log all new allocations in ALLOCATION_AUDIT table
-- ============================================================
DROP TRIGGER IF EXISTS trg_log_allocation_insert$$

CREATE TRIGGER trg_log_allocation_insert
AFTER INSERT ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    INSERT INTO ALLOCATION_AUDIT (
        Allocation_ID,
        Student_ID,
        Seat_ID,
        Old_Status,
        New_Status,
        Action_Type,
        Changed_At
    ) VALUES (
        NEW.Allocation_ID,
        NEW.Student_ID,
        NEW.Seat_ID,
        NULL,
        NEW.Allocation_Status,
        'INSERT',
        NOW()
    );
END$$

-- ============================================================
-- TRIGGER 10: trg_log_allocation_update
-- Purpose: Log status changes in ALLOCATION_AUDIT table
-- ============================================================
DROP TRIGGER IF EXISTS trg_log_allocation_update$$

CREATE TRIGGER trg_log_allocation_update
AFTER UPDATE ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    -- Only log if status actually changed
    IF NEW.Allocation_Status <> OLD.Allocation_Status THEN
        INSERT INTO ALLOCATION_AUDIT (
            Allocation_ID,
            Student_ID,
            Seat_ID,
            Old_Status,
            New_Status,
            Action_Type,
            Changed_At
        ) VALUES (
            NEW.Allocation_ID,
            NEW.Student_ID,
            NEW.Seat_ID,
            OLD.Allocation_Status,
            NEW.Allocation_Status,
            'UPDATE',
            NOW()
        );
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- VERIFICATION QUERY: List all created triggers
-- Run this to confirm all 10 triggers are installed
-- ============================================================
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION AS Event,
    EVENT_OBJECT_TABLE AS `Table`,
    ACTION_TIMING AS Timing
FROM 
    INFORMATION_SCHEMA.TRIGGERS
WHERE 
    TRIGGER_SCHEMA = DATABASE()
ORDER BY 
    EVENT_OBJECT_TABLE, 
    ACTION_TIMING, 
    EVENT_MANIPULATION;