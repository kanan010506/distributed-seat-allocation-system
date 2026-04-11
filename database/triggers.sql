-- ============================================================
-- triggers.sql — Database triggers for jee_admission_db
-- Project: JEE Counselling & Seat Allocation System
--
-- TRIGGERS IN THIS FILE:
--   1.  trg_verify_rank_before_student_insert
--   2.  trg_mark_rank_used_after_student_insert
--   3.  trg_prevent_duplicate_rank_on_update
--   4.  trg_check_seats_before_allocation       
--   5.  trg_increment_filled_seats_after_allocation
--   6.  trg_decrement_filled_seats_after_withdrawal
--   7.  trg_handle_upgrade_on_new_allocation     
--   8.  trg_sync_choice_status_after_allocation  
--   9.  trg_prevent_choice_after_allocation      
--   10. trg_log_allocation_changes               
-- ============================================================

DELIMITER $$

-- ============================================================
-- TRIGGER 1: trg_verify_rank_before_student_insert
-- ============================================================
DROP TRIGGER IF EXISTS trg_verify_rank_before_student_insert;
CREATE TRIGGER trg_verify_rank_before_student_insert
BEFORE INSERT ON STUDENT
FOR EACH ROW
BEGIN
    DECLARE v_is_used   BOOLEAN;
    DECLARE v_exists    INT;

    SELECT COUNT(*), MAX(Is_Used)
    INTO   v_exists, v_is_used
    FROM   JEE_RANK_VERIFY
    WHERE  JEE_Rank = NEW.JEE_Rank
      AND  Year     = NEW.Year;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration failed: JEE Rank not found in official records.';
    END IF;

    IF v_is_used = TRUE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration failed: This JEE Rank is already registered.';
    END IF;
END$$

-- ============================================================
-- TRIGGER 2: trg_mark_rank_used_after_student_insert
-- ============================================================
DROP TRIGGER IF EXISTS trg_mark_rank_used_after_student_insert;
CREATE TRIGGER trg_mark_rank_used_after_student_insert
AFTER INSERT ON STUDENT
FOR EACH ROW
BEGIN
    UPDATE JEE_RANK_VERIFY
    SET    Is_Used = TRUE
    WHERE  JEE_Rank = NEW.JEE_Rank
      AND  Year     = NEW.Year;
END$$

-- ============================================================
-- TRIGGER 3: trg_prevent_duplicate_rank_on_update
-- ============================================================
DROP TRIGGER IF EXISTS trg_prevent_duplicate_rank_on_update;
CREATE TRIGGER trg_prevent_duplicate_rank_on_update
BEFORE UPDATE ON STUDENT
FOR EACH ROW
BEGIN
    DECLARE v_is_used   BOOLEAN;
    DECLARE v_exists    INT;

    IF NEW.JEE_Rank <> OLD.JEE_Rank THEN

        SELECT COUNT(*), MAX(Is_Used)
        INTO   v_exists, v_is_used
        FROM   JEE_RANK_VERIFY
        WHERE  JEE_Rank = NEW.JEE_Rank
          AND  Year     = NEW.Year;

        IF v_exists = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Update failed: New JEE Rank not found in official records.';
        END IF;

        IF v_is_used = TRUE THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Update failed: New JEE Rank is already registered by another student.';
        END IF;

        UPDATE JEE_RANK_VERIFY
        SET    Is_Used = FALSE
        WHERE  JEE_Rank = OLD.JEE_Rank AND Year = OLD.Year;

        UPDATE JEE_RANK_VERIFY
        SET    Is_Used = TRUE
        WHERE  JEE_Rank = NEW.JEE_Rank AND Year = NEW.Year;

    END IF;
END$$

-- ============================================================
-- TRIGGER 4: trg_check_seats_before_allocation
-- ============================================================
DROP TRIGGER IF EXISTS trg_check_seats_before_allocation;
CREATE TRIGGER trg_check_seats_before_allocation
BEFORE INSERT ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    DECLARE v_available     INT;
    DECLARE v_active_alloc  INT;

    -- Guard 1: Check seat availability
    SELECT Available_Seats
    INTO   v_available
    FROM   SEAT_MATRIX
    WHERE  Seat_ID = NEW.Seat_ID;

    IF v_available <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Allocation failed: No seats available in this category.';
    END IF;

    -- Guard 2 : Prevent duplicate active allocation in same round
    -- A student cannot have two non-withdrawn allocations in the same round.
    SELECT COUNT(*)
    INTO   v_active_alloc
    FROM   SEAT_ALLOCATION
    WHERE  Student_ID        = NEW.Student_ID
      AND  Allocation_Round  = NEW.Allocation_Round
      AND  Allocation_Status <> 'Withdrawn';

    IF v_active_alloc > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Allocation failed: Student already has an active allocation in this round.';
    END IF;
END$$

-- ============================================================
-- TRIGGER 5: trg_increment_filled_seats_after_allocation
-- ============================================================
DROP TRIGGER IF EXISTS trg_increment_filled_seats_after_allocation;
CREATE TRIGGER trg_increment_filled_seats_after_allocation
AFTER INSERT ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    UPDATE SEAT_MATRIX
    SET    Filled_Seats = Filled_Seats + 1
    WHERE  Seat_ID = NEW.Seat_ID;
END$$

-- ============================================================
-- TRIGGER 6: trg_decrement_filled_seats_after_withdrawal
-- ============================================================
DROP TRIGGER IF EXISTS trg_decrement_filled_seats_after_withdrawal;
CREATE TRIGGER trg_decrement_filled_seats_after_withdrawal
AFTER UPDATE ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    IF NEW.Allocation_Status = 'Withdrawn'
       AND OLD.Allocation_Status <> 'Withdrawn' THEN

        UPDATE SEAT_MATRIX
        SET    Filled_Seats = Filled_Seats - 1
        WHERE  Seat_ID = OLD.Seat_ID;

    END IF;
END$$

-- ============================================================
-- TRIGGER 7: trg_handle_upgrade_on_new_allocation
-- ============================================================
DROP TRIGGER IF EXISTS trg_handle_upgrade_on_new_allocation;
CREATE TRIGGER trg_handle_upgrade_on_new_allocation
AFTER INSERT ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    -- Auto-withdraw any previous round allocation for this student
    -- Only acts if there's a prior round — does nothing in round 1
    UPDATE SEAT_ALLOCATION
    SET    Allocation_Status = 'Withdrawn'
    WHERE  Student_ID        = NEW.Student_ID
      AND  Allocation_Round  < NEW.Allocation_Round
      AND  Allocation_Status <> 'Withdrawn';
END$$

-- ============================================================
-- TRIGGER 8: trg_sync_choice_status_after_allocation
-- ============================================================
DROP TRIGGER IF EXISTS trg_sync_choice_status_after_allocation;
CREATE TRIGGER trg_sync_choice_status_after_allocation
AFTER INSERT ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    DECLARE v_program_id INT;

    SELECT Program_ID
    INTO   v_program_id
    FROM   SEAT_MATRIX
    WHERE  Seat_ID = NEW.Seat_ID;

    -- Mark the allocated choice regardless of its current status
    UPDATE CHOICE
    SET    Status = 'Allocated'
    WHERE  Student_ID  = NEW.Student_ID
      AND  Program_ID  = v_program_id;

    -- Reset all other choices back to Active
    -- (important for upgrade rounds — old allocated choice is no longer current)
    UPDATE CHOICE
    SET    Status = 'Active'
    WHERE  Student_ID  = NEW.Student_ID
      AND  Program_ID  <> v_program_id
      AND  Status      = 'Allocated';
END$$

-- ============================================================
-- TRIGGER 9: trg_prevent_choice_after_allocation
-- ============================================================
DROP TRIGGER IF EXISTS trg_prevent_choice_after_allocation;
CREATE TRIGGER trg_prevent_choice_after_allocation
BEFORE INSERT ON CHOICE
FOR EACH ROW
BEGIN
    DECLARE v_has_seat INT;

    -- Block if student has ANY non-withdrawn allocation
    -- (covers both 'Allocated' and 'Confirmed' states)
    SELECT COUNT(*)
    INTO   v_has_seat
    FROM   SEAT_ALLOCATION
    WHERE  Student_ID        = NEW.Student_ID
      AND  Allocation_Status <> 'Withdrawn';

    IF v_has_seat > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot add choices: Student already has an active seat allocation.';
    END IF;
END$$

-- ============================================================
-- TRIGGER 10: trg_log_allocation_changes
-- ============================================================
DROP TRIGGER IF EXISTS trg_log_allocation_insert;
CREATE TRIGGER trg_log_allocation_insert
AFTER INSERT ON SEAT_ALLOCATION
FOR EACH ROW
BEGIN
    INSERT INTO ALLOCATION_AUDIT (
        Allocation_ID,
        Student_ID,
        Seat_ID,
        Round,
        Old_Status,
        New_Status,
        Action_Type,
        Changed_At
    ) VALUES (
        NEW.Allocation_ID,
        NEW.Student_ID,
        NEW.Seat_ID,
        NEW.Allocation_Round,
        NULL,
        NEW.Allocation_Status,
        'INSERT',
        NOW()
    );
END$$

-- ============================================================
-- TRIGGER 11 : trg_log_allocation_update
-- ============================================================
DROP TRIGGER IF EXISTS trg_log_allocation_update;
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
            Round,
            Old_Status,
            New_Status,
            Action_Type,
            Changed_At
        ) VALUES (
            NEW.Allocation_ID,
            NEW.Student_ID,
            NEW.Seat_ID,
            NEW.Allocation_Round,
            OLD.Allocation_Status,
            NEW.Allocation_Status,
            'UPDATE',
            NOW()
        );
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- Verify: list all triggers created
-- ============================================================
SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION  AS Event,
    EVENT_OBJECT_TABLE  AS `Table`,
    ACTION_TIMING       AS Timing
FROM 
    INFORMATION_SCHEMA.TRIGGERS
WHERE 
    TRIGGER_SCHEMA = DATABASE()
ORDER BY 
    EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION;