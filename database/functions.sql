-- ============================================================
-- functions.sql — Stored Functions for jee_admission_db
-- Project: Distributed Seat Allocation & Admission System
-- Course Code: UCS310 | Thapar Institute of Engineering and Technology
--
-- FUNCTIONS IN THIS FILE (15 Total):
--   1.  GetAvailableSeats()          — Seats left for a program+category
--   2.  CheckEligibility()           — Is a student eligible for a seat?
--   3.  CalculateCutoff()            — Dynamic cutoff rank for a seat row
--   4.  GetStudentCategory()         — Fetch category string for a student
--   5.  GetStudentRank()             — Fetch JEE rank for a student
--   6.  GetFilledSeats()             — Seats filled in a program+category
--   7.  GetTotalSeats()              — Total seats in a program+category
--   8.  IsStudentAllocated()         — Does student have a live allocation?
--   9. GetProgramInstitute()        — Which institute owns a program?
--   10. GetInstituteType()           — IIT / NIT / IIIT / Private?
--   11. GetCategoryFillPercent()     — % fill for a program+category
--   12. GetStudentTopChoice()        — Highest-preference active program
--   13. GetRankBand()                — Classify rank: Top / Mid / General / High
--   14. IsRankVerified()             — Is JEE rank in official registry?
--
-- Run Order: schema.sql → triggers.sql → seed.sql → functions.sql
--
-- CORRECTED IN THIS VERSION:
--   ✓ Changed RETURNS BOOLEAN to RETURNS INT (MySQL compatibility)
--   ✓ All functions return 1 (true) or 0 (false) for boolean logic
--   ✓ Added DEFAULT values to all DECLARE statements
--   ✓ NULL safety checks before all comparisons
--   ✓ Simplified verification query (removed IS_DETERMINISTIC)
--   ✓ All functions MySQL 8.0+ compatible
--   ✓ Better error handling and edge case coverage
-- ============================================================

DELIMITER $$

-- ============================================================
-- FUNCTION 1: GetAvailableSeats
-- Purpose: Returns remaining available seats for a program+category
-- Returns: INT (0 if none or not found)
-- Usage:   SELECT GetAvailableSeats(1, 'General');
-- ============================================================
DROP FUNCTION IF EXISTS GetAvailableSeats$$

CREATE FUNCTION GetAvailableSeats(
    p_program_id INT,
    p_category ENUM('General','OBC','SC','ST','EWS')
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_available INT DEFAULT 0;

    SELECT COALESCE(Available_Seats, 0)
    INTO v_available
    FROM SEAT_MATRIX
    WHERE Program_ID = p_program_id
      AND Category = p_category
    LIMIT 1;

    RETURN COALESCE(v_available, 0);
END$$


-- ============================================================
-- FUNCTION 2: CheckEligibility
-- Purpose: Verify if student qualifies for a seat based on:
--          - Student rank ≤ program cutoff for their category
--          - At least one seat available
-- Returns: INT (1 = eligible, 0 = not eligible)
-- Usage:   SELECT CheckEligibility(5, 12);
-- ============================================================
DROP FUNCTION IF EXISTS CheckEligibility$$

CREATE FUNCTION CheckEligibility(
    p_student_id INT,
    p_program_id INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_rank INT DEFAULT 0;
    DECLARE v_category VARCHAR(10) DEFAULT '';
    DECLARE v_cutoff INT DEFAULT 0;
    DECLARE v_available INT DEFAULT 0;
    DECLARE v_result INT DEFAULT 0;

    -- Fetch student rank and category
    SELECT COALESCE(JEE_Rank, 0), COALESCE(Category, '')
    INTO v_rank, v_category
    FROM STUDENT
    WHERE Student_ID = p_student_id
    LIMIT 1;

    -- If student not found or invalid rank
    IF v_rank <= 0 OR v_category = '' THEN
        RETURN 0;
    END IF;

    -- Fetch cutoff and available seats for program + student's category
    SELECT COALESCE(Cutoff_Rank, 0), COALESCE(Available_Seats, 0)
    INTO v_cutoff, v_available
    FROM SEAT_MATRIX
    WHERE Program_ID = p_program_id
      AND Category = v_category
    LIMIT 1;

    -- Eligible if: cutoff exists, seats available, and rank within cutoff
    IF v_cutoff > 0 AND v_available > 0 AND v_rank <= v_cutoff THEN
        SET v_result = 1;
    ELSE
        SET v_result = 0;
    END IF;

    RETURN v_result;
END$$


-- ============================================================
-- FUNCTION 3: CalculateCutoff
-- Purpose: Dynamically calculate effective cutoff for a seat
--          Returns worst (highest) rank currently allocated
--          Falls back to static Cutoff_Rank when no allocations
-- Returns: INT cutoff rank (NULL if seat not found)
-- Usage:   SELECT CalculateCutoff(3);
-- ============================================================
DROP FUNCTION IF EXISTS CalculateCutoff$$

CREATE FUNCTION CalculateCutoff(
    p_seat_id INT
)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_dynamic_cutoff INT DEFAULT NULL;
    DECLARE v_static_cutoff INT DEFAULT NULL;

    -- Dynamic cutoff: worst (highest) rank of allocated students
    SELECT MAX(COALESCE(s.JEE_Rank, 0))
    INTO v_dynamic_cutoff
    FROM SEAT_ALLOCATION sa
    JOIN STUDENT s ON s.Student_ID = sa.Student_ID
    WHERE sa.Seat_ID = p_seat_id
      AND sa.Allocation_Status <> 'Withdrawn';

    -- Static cutoff from SEAT_MATRIX
    SELECT COALESCE(Cutoff_Rank, NULL)
    INTO v_static_cutoff
    FROM SEAT_MATRIX
    WHERE Seat_ID = p_seat_id
    LIMIT 1;

    -- Return dynamic if available and greater than 0, else static
    IF v_dynamic_cutoff IS NOT NULL AND v_dynamic_cutoff > 0 THEN
        RETURN v_dynamic_cutoff;
    ELSE
        RETURN v_static_cutoff;
    END IF;
END$$


-- ============================================================
-- FUNCTION 4: GetStudentCategory
-- Purpose: Returns the reservation category of a student
-- Returns: VARCHAR (category string, or NULL if not found)
-- Usage:   SELECT GetStudentCategory(7);
-- ============================================================
DROP FUNCTION IF EXISTS GetStudentCategory$$

CREATE FUNCTION GetStudentCategory(
    p_student_id INT
)
RETURNS VARCHAR(10)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_category VARCHAR(10) DEFAULT NULL;

    SELECT Category
    INTO v_category
    FROM STUDENT
    WHERE Student_ID = p_student_id
    LIMIT 1;

    RETURN v_category;
END$$


-- ============================================================
-- FUNCTION 5: GetStudentRank
-- Purpose: Returns the JEE rank of a student
-- Returns: INT rank (NULL if not found)
-- Usage:   SELECT GetStudentRank(1);
-- ============================================================
DROP FUNCTION IF EXISTS GetStudentRank$$

CREATE FUNCTION GetStudentRank(
    p_student_id INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_rank INT DEFAULT NULL;

    SELECT JEE_Rank
    INTO v_rank
    FROM STUDENT
    WHERE Student_ID = p_student_id
    LIMIT 1;

    RETURN v_rank;
END$$


-- ============================================================
-- FUNCTION 6: GetFilledSeats
-- Purpose: Returns number of seats filled for program+category
-- Returns: INT filled count (0 if not found)
-- Usage:   SELECT GetFilledSeats(9, 'OBC');
-- ============================================================
DROP FUNCTION IF EXISTS GetFilledSeats$$

CREATE FUNCTION GetFilledSeats(
    p_program_id INT,
    p_category ENUM('General','OBC','SC','ST','EWS')
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_filled INT DEFAULT 0;

    SELECT COALESCE(Filled_Seats, 0)
    INTO v_filled
    FROM SEAT_MATRIX
    WHERE Program_ID = p_program_id
      AND Category = p_category
    LIMIT 1;

    RETURN COALESCE(v_filled, 0);
END$$


-- ============================================================
-- FUNCTION 7: GetTotalSeats
-- Purpose: Returns total sanctioned seats for program+category
-- Returns: INT total seats (0 if not found)
-- Usage:   SELECT GetTotalSeats(1, 'General');
-- ============================================================
DROP FUNCTION IF EXISTS GetTotalSeats$$

CREATE FUNCTION GetTotalSeats(
    p_program_id INT,
    p_category ENUM('General','OBC','SC','ST','EWS')
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COALESCE(Total_Seats, 0)
    INTO v_total
    FROM SEAT_MATRIX
    WHERE Program_ID = p_program_id
      AND Category = p_category
    LIMIT 1;

    RETURN COALESCE(v_total, 0);
END$$


-- ============================================================
-- FUNCTION 8: IsStudentAllocated
-- Purpose: Check if student has any active (non-withdrawn)
--          seat allocation currently
-- Returns: INT (1 = allocated, 0 = not allocated)
-- Usage:   SELECT IsStudentAllocated(3);
-- ============================================================
DROP FUNCTION IF EXISTS IsStudentAllocated$$

CREATE FUNCTION IsStudentAllocated(
    p_student_id INT
)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_count
    FROM SEAT_ALLOCATION
    WHERE Student_ID = p_student_id
      AND Allocation_Status <> 'Withdrawn';

    RETURN CASE WHEN v_count > 0 THEN 1 ELSE 0 END;
END$$


-- ============================================================
-- FUNCTION 9: GetProgramInstitute
-- Purpose: Returns the Institute_ID that owns a program
-- Returns: INT Institute_ID (NULL if not found)
-- Usage:   SELECT GetProgramInstitute(7);
-- ============================================================
DROP FUNCTION IF EXISTS GetProgramInstitute$$

CREATE FUNCTION GetProgramInstitute(
    p_program_id INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_institute_id INT DEFAULT NULL;

    SELECT Institute_ID
    INTO v_institute_id
    FROM PROGRAM
    WHERE Program_ID = p_program_id
    LIMIT 1;

    RETURN v_institute_id;
END$$


-- ============================================================
-- FUNCTION 10: GetInstituteType
-- Purpose: Returns type of institute
--          (IIT / NIT / IIIT / Private)
-- Returns: VARCHAR institute type (NULL if not found)
-- Usage:   SELECT GetInstituteType(1);
-- ============================================================
DROP FUNCTION IF EXISTS GetInstituteType$$

CREATE FUNCTION GetInstituteType(
    p_institute_id INT
)
RETURNS VARCHAR(10)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_type VARCHAR(10) DEFAULT NULL;

    SELECT Institute_Type
    INTO v_type
    FROM INSTITUTE
    WHERE Institute_ID = p_institute_id
    LIMIT 1;

    RETURN v_type;
END$$


-- ============================================================
-- FUNCTION 11: GetCategoryFillPercent
-- Purpose: Returns percentage of seats filled for
--          program+category as DECIMAL(5,2)
-- Returns: DECIMAL(5,2) (e.g., 75.00 means 75% filled)
-- Usage:   SELECT GetCategoryFillPercent(1, 'General');
-- ============================================================
DROP FUNCTION IF EXISTS GetCategoryFillPercent$$

CREATE FUNCTION GetCategoryFillPercent(
    p_program_id INT,
    p_category ENUM('General','OBC','SC','ST','EWS')
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_filled INT DEFAULT 0;
    DECLARE v_pct DECIMAL(5,2) DEFAULT 0.00;

    SELECT COALESCE(Total_Seats, 0),
           COALESCE(Filled_Seats, 0)
    INTO v_total, v_filled
    FROM SEAT_MATRIX
    WHERE Program_ID = p_program_id
      AND Category = p_category
    LIMIT 1;

    -- Calculate percentage only if total > 0
    IF v_total > 0 THEN
        SET v_pct = ROUND((CAST(v_filled AS DECIMAL(10,2)) / CAST(v_total AS DECIMAL(10,2))) * 100, 2);
    ELSE
        SET v_pct = 0.00;
    END IF;

    RETURN v_pct;
END$$


-- ============================================================
-- FUNCTION 12: GetStudentTopChoice
-- Purpose: Returns Program_ID of highest-preference active choice
--          Used by AllocateSeats() to determine next program to try
-- Returns: INT Program_ID (NULL if no active choices)
-- Usage:   SELECT GetStudentTopChoice(4);
-- ============================================================
DROP FUNCTION IF EXISTS GetStudentTopChoice$$

CREATE FUNCTION GetStudentTopChoice(
    p_student_id INT
)
RETURNS INT
NOT DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_program_id INT DEFAULT NULL;

    SELECT Program_ID
    INTO v_program_id
    FROM CHOICE
    WHERE Student_ID = p_student_id
      AND Status = 'Active'
    ORDER BY Preference_Order ASC
    LIMIT 1;

    RETURN v_program_id;
END$$


-- ============================================================
-- FUNCTION 13: GetRankBand
-- Purpose: Classifies a JEE rank into descriptive band
--          for reporting and analytics
--          ≤  1,000  → 'Top'
--          ≤  5,000  → 'High'
--          ≤ 20,000  → 'Mid'
--          ≤ 50,000  → 'General'
--          > 50,000  → 'Out of Range'
-- Returns: VARCHAR(15) band label
-- Usage:   SELECT GetRankBand(430);      -- returns 'Top'
--          SELECT GetRankBand(GetStudentRank(11));
-- ============================================================
DROP FUNCTION IF EXISTS GetRankBand$$

CREATE FUNCTION GetRankBand(
    p_rank INT
)
RETURNS VARCHAR(15)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_band VARCHAR(15) DEFAULT 'Invalid';

    IF p_rank IS NULL OR p_rank <= 0 THEN
        SET v_band = 'Invalid';
    ELSEIF p_rank <= 1000 THEN
        SET v_band = 'Top';
    ELSEIF p_rank <= 5000 THEN
        SET v_band = 'High';
    ELSEIF p_rank <= 20000 THEN
        SET v_band = 'Mid';
    ELSEIF p_rank <= 50000 THEN
        SET v_band = 'General';
    ELSE
        SET v_band = 'Out of Range';
    END IF;

    RETURN v_band;
END$$


-- ============================================================
-- FUNCTION 14: IsRankVerified
-- Purpose: Check if JEE rank+year exists in official registry
--          Does NOT check if already used (Trigger 1 handles that)
-- Returns: INT (1 = rank in registry, 0 = not found)
-- Usage:   SELECT IsRankVerified(85, 2025);     -- returns 1
--          SELECT IsRankVerified(99999, 2025);  -- returns 0
-- ============================================================
DROP FUNCTION IF EXISTS IsRankVerified$$

CREATE FUNCTION IsRankVerified(
    p_rank INT,
    p_year YEAR
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_count
    FROM JEE_RANK_VERIFY
    WHERE JEE_Rank = p_rank
      AND Year = p_year;

    RETURN CASE WHEN v_count > 0 THEN 1 ELSE 0 END;
END$$

DELIMITER ;

-- ============================================================
-- VERIFICATION: List all functions created
-- ============================================================
SELECT
    ROUTINE_NAME AS Function_Name,
    DATA_TYPE AS Return_Type,
    SQL_DATA_ACCESS AS Data_Access,
    CREATED AS Created_At
FROM
    INFORMATION_SCHEMA.ROUTINES
WHERE
    ROUTINE_SCHEMA = DATABASE()
    AND ROUTINE_TYPE = 'FUNCTION'
ORDER BY
    ROUTINE_NAME;

-- ============================================================
-- QUICK TEST QUERIES (Uncomment after seed.sql)
-- ============================================================

-- -- F1: Available General seats in IIT Bombay CSE (Program 1)
-- SELECT GetAvailableSeats(1, 'General') AS AvailableSeats;

-- -- F2: Is Student 1 (rank 85) eligible for IIT Bombay CSE?
-- SELECT CheckEligibility(1, 1) AS IsEligible;

-- -- F3: Dynamic cutoff for Seat_ID 1 (IIT-B CSE General)
-- SELECT CalculateCutoff(1) AS EffectiveCutoff;

-- -- F4: Category of Student 7 (Rohit Mehta, OBC)
-- SELECT GetStudentCategory(7) AS Category;

-- -- F5: JEE rank of Student 12 (Ananya Reddy, rank 1350)
-- SELECT GetStudentRank(12) AS JEE_Rank;

-- -- F6: Filled seats — NIT Trichy CSE General
-- SELECT GetFilledSeats(9, 'General') AS FilledSeats;

-- -- F7: Total seats — IIT Bombay CSE OBC
-- SELECT GetTotalSeats(1, 'OBC') AS TotalSeats;

-- -- F8: Is Student 20 (Farhan) allocated?
-- SELECT IsStudentAllocated(20) AS IsAllocated;


-- -- F9: Which institute owns Program 16?
-- SELECT GetProgramInstitute(16) AS Institute_ID;

-- -- F10: Type of Institute 7 (IIIT Hyderabad)
-- SELECT GetInstituteType(7) AS InstituteType;

-- -- F11: Fill percentage for IIT Bombay CSE General
-- SELECT GetCategoryFillPercent(1, 'General') AS FillPercent;

-- -- F12: Top active choice for Student 4 (Karthik Menon)
-- SELECT GetStudentTopChoice(4) AS TopChoiceProgram;

-- -- F13: Rank band for rank 7800
-- SELECT GetRankBand(7800) AS RankBand;

-- -- F14: Is rank 85 from 2025 in official registry?
-- SELECT IsRankVerified(85, 2025) AS IsVerified;