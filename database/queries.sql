-- ============================================================
-- queries.sql — Demonstration & Reporting Queries
-- Project : Distributed Seat Allocation & Admission System
-- Course  : UCS310  |  Thapar Institute of Engineering & Technology
-- Authors : Rohan Bansal, Kanan, Samriddhi Gupta
--
-- HOW TO USE
--   Run this file section-by-section in MySQL Workbench.
--   Every query is self-contained and executable after
--   schema.sql, triggers.sql, procedures.sql, and seed.sql
--   have been loaded into jee_admission_db.
--
-- SECTIONS
--   1. Basic SELECT Queries
--   2. JOIN Queries
--   3. Aggregate Queries
--   4. GROUP BY & HAVING Queries
--   5. Subqueries
--   6. Real-World Useful Queries
-- ============================================================

USE jee_admission_db;

-- ============================================================
-- SECTION 1 : BASIC SELECT QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 1.1  All students sorted by JEE rank (best rank first)
-- ------------------------------------------------------------
SELECT
    Student_ID,
    Name,
    Email,
    Gender,
    Category,
    JEE_Rank,
    Year
FROM   STUDENT
ORDER  BY JEE_Rank ASC;

-- ------------------------------------------------------------
-- 1.2  All programs with their institute details
-- ------------------------------------------------------------
SELECT
    P.Program_ID,
    P.Program_Name,
    P.Degree,
    P.Duration_Years,
    I.Institute_Name,
    I.Location,
    I.Institute_Type
FROM   PROGRAM    P
JOIN   INSTITUTE  I  ON I.Institute_ID = P.Institute_ID
ORDER  BY I.Institute_Name, P.Program_Name;

-- ------------------------------------------------------------
-- 1.3  Seat matrix for every program
--      (Available_Seats is a GENERATED column — shown as-is)
-- ------------------------------------------------------------
SELECT
    SM.Seat_ID,
    I.Institute_Name,
    P.Program_Name,
    P.Degree,
    SM.Category,
    SM.Total_Seats,
    SM.Filled_Seats,
    SM.Available_Seats,
    SM.Cutoff_Rank
FROM   SEAT_MATRIX  SM
JOIN   PROGRAM      P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE    I   ON I.Institute_ID = P.Institute_ID
ORDER  BY I.Institute_Name, P.Program_Name, SM.Category;

-- ------------------------------------------------------------
-- 1.4  All active seat allocations (non-withdrawn)
-- ------------------------------------------------------------
SELECT
    SA.Allocation_ID,
    S.Name           AS Student_Name,
    S.JEE_Rank,
    S.Category,
    P.Program_Name,
    I.Institute_Name,
    SA.Allocation_Status,
    SA.Admission_Status,
    SA.Allocation_Date
FROM   SEAT_ALLOCATION  SA
JOIN   STUDENT          S   ON S.Student_ID  = SA.Student_ID
JOIN   SEAT_MATRIX      SM  ON SM.Seat_ID    = SA.Seat_ID
JOIN   PROGRAM          P   ON P.Program_ID  = SM.Program_ID
JOIN   INSTITUTE        I   ON I.Institute_ID = P.Institute_ID
WHERE  SA.Allocation_Status <> 'Withdrawn'
ORDER  BY  S.JEE_Rank;

-- ------------------------------------------------------------
-- 1.5  All student choice preferences (ordered list)
-- ------------------------------------------------------------
SELECT
    C.Choice_ID,
    S.Name              AS Student_Name,
    S.JEE_Rank,
    C.Preference_Order,
    P.Program_Name,
    P.Degree,
    I.Institute_Name,
    C.Status,
    C.Choice_Date
FROM   CHOICE      C
JOIN   STUDENT     S   ON S.Student_ID   = C.Student_ID
JOIN   PROGRAM     P   ON P.Program_ID   = C.Program_ID
JOIN   INSTITUTE   I   ON I.Institute_ID = P.Institute_ID
ORDER  BY S.JEE_Rank, C.Preference_Order;


-- ============================================================
-- SECTION 2 : JOIN QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 2.1  Students with their allocated program and institute
--      (only confirmed/active allocations)
-- ------------------------------------------------------------
SELECT
    S.Student_ID,
    S.Name                  AS Student_Name,
    S.JEE_Rank,
    S.Category,
    P.Program_Name,
    P.Degree,
    I.Institute_Name,
    I.Location,
    SM.Category             AS Seat_Category,
    SA.Allocation_Status,
    SA.Admission_Status
FROM   SEAT_ALLOCATION  SA
JOIN   STUDENT          S   ON S.Student_ID   = SA.Student_ID
JOIN   SEAT_MATRIX      SM  ON SM.Seat_ID     = SA.Seat_ID
JOIN   PROGRAM          P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE        I   ON I.Institute_ID = P.Institute_ID
WHERE  SA.Allocation_Status = 'Allocated'
ORDER  BY S.JEE_Rank;

-- ------------------------------------------------------------
-- 2.2  Each student's full preference list with current status
-- ------------------------------------------------------------
SELECT
    S.Name              AS Student_Name,
    S.JEE_Rank,
    S.Category,
    C.Preference_Order,
    P.Program_Name,
    P.Degree,
    I.Institute_Name,
    SM.Available_Seats,
    C.Status            AS Choice_Status
FROM   CHOICE      C
JOIN   STUDENT     S    ON S.Student_ID   = C.Student_ID
JOIN   PROGRAM     P    ON P.Program_ID   = C.Program_ID
JOIN   INSTITUTE   I    ON I.Institute_ID = P.Institute_ID
-- Join to the seat row matching the student's own category
LEFT JOIN SEAT_MATRIX SM
    ON  SM.Program_ID = P.Program_ID
    AND SM.Category   = S.Category
ORDER  BY S.JEE_Rank, C.Preference_Order;

-- ------------------------------------------------------------
-- 2.3  Program-wise student allocations
--      (count + list of allocated students per program)
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    P.Program_Name,
    P.Degree,
    SM.Category             AS Seat_Category,
    S.Name                  AS Student_Name,
    S.JEE_Rank,
    SA.Allocation_Status
FROM   SEAT_ALLOCATION  SA
JOIN   STUDENT          S   ON S.Student_ID   = SA.Student_ID
JOIN   SEAT_MATRIX      SM  ON SM.Seat_ID     = SA.Seat_ID
JOIN   PROGRAM          P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE        I   ON I.Institute_ID = P.Institute_ID
WHERE  SA.Allocation_Status <> 'Withdrawn'
ORDER  BY I.Institute_Name, P.Program_Name, SM.Category, S.JEE_Rank;

-- ------------------------------------------------------------
-- 2.4  Students and their full registration + allocation detail
--      (INNER JOIN — only students who have been allocated)
-- ------------------------------------------------------------
SELECT
    S.Student_ID,
    S.Name,
    S.Email,
    S.Mobile_No,
    S.Gender,
    S.Category,
    S.JEE_Rank,
    P.Program_Name,
    I.Institute_Name,
    SA.Allocation_Date,
    SA.Admission_Status
FROM   STUDENT          S
JOIN   SEAT_ALLOCATION  SA  ON SA.Student_ID  = S.Student_ID
JOIN   SEAT_MATRIX      SM  ON SM.Seat_ID     = SA.Seat_ID
JOIN   PROGRAM          P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE        I   ON I.Institute_ID = P.Institute_ID
WHERE  SA.Allocation_Status <> 'Withdrawn'
ORDER  BY S.JEE_Rank;


-- ============================================================
-- SECTION 3 : AGGREGATE QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 3.1  Total seats, filled seats, available seats per program
--      aggregated across all categories
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    P.Program_Name,
    P.Degree,
    SUM(SM.Total_Seats)     AS Total_Seats,
    SUM(SM.Filled_Seats)    AS Filled_Seats,
    SUM(SM.Available_Seats) AS Available_Seats,
    ROUND(
        100.0 * SUM(SM.Filled_Seats) / NULLIF(SUM(SM.Total_Seats), 0),
        2
    )                       AS Fill_Percentage
FROM   SEAT_MATRIX  SM
JOIN   PROGRAM      P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE    I   ON I.Institute_ID = P.Institute_ID
GROUP  BY I.Institute_Name, P.Program_Name, P.Degree
ORDER  BY Fill_Percentage DESC;

-- ------------------------------------------------------------
-- 3.2  Count of allocated (non-withdrawn) students per program
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    P.Program_Name,
    P.Degree,
    COUNT(SA.Allocation_ID) AS Allocated_Students
FROM   SEAT_ALLOCATION  SA
JOIN   SEAT_MATRIX      SM  ON SM.Seat_ID     = SA.Seat_ID
JOIN   PROGRAM          P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE        I   ON I.Institute_ID = P.Institute_ID
WHERE  SA.Allocation_Status <> 'Withdrawn'
GROUP  BY I.Institute_Name, P.Program_Name, P.Degree
ORDER  BY Allocated_Students DESC;

-- ------------------------------------------------------------
-- 3.3  Average JEE rank of allocated students per program
--      (lower average = more competitive program)
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    P.Program_Name,
    P.Degree,
    SM.Category,
    COUNT(SA.Allocation_ID)     AS Allocated_Count,
    MIN(S.JEE_Rank)             AS Best_Rank,
    MAX(S.JEE_Rank)             AS Worst_Rank,
    ROUND(AVG(S.JEE_Rank), 0)  AS Avg_Rank
FROM   SEAT_ALLOCATION  SA
JOIN   STUDENT          S   ON S.Student_ID   = SA.Student_ID
JOIN   SEAT_MATRIX      SM  ON SM.Seat_ID     = SA.Seat_ID
JOIN   PROGRAM          P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE        I   ON I.Institute_ID = P.Institute_ID
WHERE  SA.Allocation_Status <> 'Withdrawn'
GROUP  BY I.Institute_Name, P.Program_Name, P.Degree, SM.Category
ORDER  BY Avg_Rank ASC;

-- ------------------------------------------------------------
-- 3.4  Category-wise seat usage summary across all programs
-- ------------------------------------------------------------
SELECT
    SM.Category,
    SUM(SM.Total_Seats)     AS Total_Seats,
    SUM(SM.Filled_Seats)    AS Filled_Seats,
    SUM(SM.Available_Seats) AS Available_Seats,
    ROUND(
        100.0 * SUM(SM.Filled_Seats) / NULLIF(SUM(SM.Total_Seats), 0),
        2
    )                       AS Utilisation_Pct
FROM   SEAT_MATRIX SM
GROUP  BY SM.Category
ORDER  BY Utilisation_Pct DESC;

-- ------------------------------------------------------------
-- 3.5  Round-wise allocation summary
-- ------------------------------------------------------------
SELECT
    COUNT(*)                                    AS Total_Actions,
    SUM(SA.Allocation_Status = 'Allocated')     AS Allocated,
    SUM(SA.Allocation_Status = 'Withdrawn')     AS Withdrawn,
    SUM(SA.Admission_Status  = 'Confirmed')     AS Confirmed,
    SUM(SA.Admission_Status  = 'Pending')       AS Pending
FROM   SEAT_ALLOCATION SA;


-- ============================================================
-- SECTION 4 : GROUP BY & HAVING QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 4.1  Programs with more than 2 active allocations
--      (change threshold as needed for your seed data)
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    P.Program_Name,
    P.Degree,
    COUNT(SA.Allocation_ID) AS Active_Allocations
FROM   SEAT_ALLOCATION  SA
JOIN   SEAT_MATRIX      SM  ON SM.Seat_ID     = SA.Seat_ID
JOIN   PROGRAM          P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE        I   ON I.Institute_ID = P.Institute_ID
WHERE  SA.Allocation_Status <> 'Withdrawn'
GROUP  BY I.Institute_Name, P.Program_Name, P.Degree
HAVING COUNT(SA.Allocation_ID) > 2
ORDER  BY Active_Allocations DESC;

-- ------------------------------------------------------------
-- 4.2  Seat matrix rows where available seats have fallen
--      below 20% of total capacity (critically low stock)
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    P.Program_Name,
    SM.Category,
    SM.Total_Seats,
    SM.Filled_Seats,
    SM.Available_Seats,
    ROUND(
        100.0 * SM.Available_Seats / NULLIF(SM.Total_Seats, 0),
        2
    )   AS Available_Pct
FROM   SEAT_MATRIX  SM
JOIN   PROGRAM      P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE    I   ON I.Institute_ID = P.Institute_ID
GROUP  BY
    I.Institute_Name, P.Program_Name,
    SM.Category, SM.Total_Seats,
    SM.Filled_Seats, SM.Available_Seats
HAVING Available_Pct < 20
ORDER  BY Available_Pct ASC;

-- ------------------------------------------------------------
-- 4.3  Students who submitted more than 3 choices
-- ------------------------------------------------------------
SELECT
    S.Student_ID,
    S.Name,
    S.JEE_Rank,
    COUNT(C.Choice_ID)  AS Total_Choices
FROM   CHOICE    C
JOIN   STUDENT   S  ON S.Student_ID = C.Student_ID
GROUP  BY S.Student_ID, S.Name, S.JEE_Rank
HAVING COUNT(C.Choice_ID) > 3
ORDER  BY Total_Choices DESC;

-- ------------------------------------------------------------
-- 4.4  Institutes with multiple programs that still have
--      available seats
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    I.Institute_Type,
    COUNT(DISTINCT P.Program_ID)    AS Programs_With_Vacancy
FROM   SEAT_MATRIX  SM
JOIN   PROGRAM      P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE    I   ON I.Institute_ID = P.Institute_ID
WHERE  SM.Available_Seats > 0
GROUP  BY I.Institute_Name, I.Institute_Type
HAVING COUNT(DISTINCT P.Program_ID) > 1
ORDER  BY Programs_With_Vacancy DESC;


-- ============================================================
-- SECTION 5 : SUBQUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 5.1  Students whose rank is better than the overall average
--      rank of all registered students
-- ------------------------------------------------------------
SELECT
    Student_ID,
    Name,
    JEE_Rank,
    Category
FROM   STUDENT
WHERE  JEE_Rank < (
           SELECT AVG(JEE_Rank) FROM STUDENT
       )
ORDER  BY JEE_Rank ASC;

-- ------------------------------------------------------------
-- 5.2  Program(s) with the highest number of active allocations
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    P.Program_Name,
    P.Degree,
    alloc_counts.Alloc_Count
FROM   PROGRAM    P
JOIN   INSTITUTE  I  ON I.Institute_ID = P.Institute_ID
JOIN  (
          SELECT  SM.Program_ID,
                  COUNT(SA.Allocation_ID) AS Alloc_Count
          FROM    SEAT_ALLOCATION SA
          JOIN    SEAT_MATRIX     SM ON SM.Seat_ID = SA.Seat_ID
          WHERE   SA.Allocation_Status <> 'Withdrawn'
          GROUP   BY SM.Program_ID
      ) alloc_counts  ON alloc_counts.Program_ID = P.Program_ID
WHERE  alloc_counts.Alloc_Count = (
           SELECT MAX(sub.cnt)
           FROM  (
                     SELECT  COUNT(SA2.Allocation_ID) AS cnt
                     FROM    SEAT_ALLOCATION SA2
                     JOIN    SEAT_MATRIX     SM2 ON SM2.Seat_ID = SA2.Seat_ID
                     WHERE   SA2.Allocation_Status <> 'Withdrawn'
                     GROUP   BY SM2.Program_ID
                 ) sub
       )
ORDER  BY I.Institute_Name, P.Program_Name;

-- ------------------------------------------------------------
-- 5.3  Students who did NOT receive any seat allocation
--      (registered but never allocated, or all withdrawn)
-- ------------------------------------------------------------
SELECT
    S.Student_ID,
    S.Name,
    S.Email,
    S.JEE_Rank,
    S.Category
FROM   STUDENT S
WHERE  S.Student_ID NOT IN (
           SELECT Student_ID
           FROM   SEAT_ALLOCATION
           WHERE  Allocation_Status <> 'Withdrawn'
       )
ORDER  BY S.JEE_Rank ASC;

-- ------------------------------------------------------------
-- 5.4  Students who filed choices but never got allocated
-- ------------------------------------------------------------
SELECT
    S.Student_ID,
    S.Name,
    S.JEE_Rank,
    S.Category,
    COUNT(C.Choice_ID) AS Choices_Filed
FROM   STUDENT  S
JOIN   CHOICE   C  ON C.Student_ID = S.Student_ID
WHERE  S.Student_ID NOT IN (
           SELECT Student_ID
           FROM   SEAT_ALLOCATION
           WHERE  Allocation_Status <> 'Withdrawn'
       )
GROUP  BY S.Student_ID, S.Name, S.JEE_Rank, S.Category
ORDER  BY S.JEE_Rank;

-- ------------------------------------------------------------
-- 5.5  Programs that are fully filled (no available seats
--      in ANY category for that program)
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    P.Program_Name,
    P.Degree
FROM   PROGRAM    P
JOIN   INSTITUTE  I  ON I.Institute_ID = P.Institute_ID
WHERE  P.Program_ID NOT IN (
           SELECT Program_ID
           FROM   SEAT_MATRIX
           WHERE  Available_Seats > 0
       )
ORDER  BY I.Institute_Name, P.Program_Name;

-- ------------------------------------------------------------
-- 5.6  Students whose first choice was successfully allocated
-- ------------------------------------------------------------
SELECT
    S.Student_ID,
    S.Name,
    S.JEE_Rank,
    P.Program_Name,
    I.Institute_Name
FROM   STUDENT  S
JOIN   CHOICE   C   ON  C.Student_ID      = S.Student_ID
                    AND C.Preference_Order = 1
                    AND C.Status          = 'Allocated'
JOIN   PROGRAM  P   ON P.Program_ID   = C.Program_ID
JOIN   INSTITUTE I  ON I.Institute_ID = P.Institute_ID
ORDER  BY S.JEE_Rank;

-- ============================================================
-- SECTION 6 : REAL-WORLD USEFUL QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- 6.1  Top N students with their allocation status
--      Change the LIMIT value to get top 5, 10, 20, etc.
-- ------------------------------------------------------------
SELECT
    S.Student_ID,
    S.Name,
    S.JEE_Rank,
    S.Category,
    COALESCE(P.Program_Name,  'Not Allocated') AS Program_Name,
    COALESCE(I.Institute_Name,'Not Allocated') AS Institute_Name,
    COALESCE(SA.Allocation_Status, 'Pending')  AS Allocation_Status,
    COALESCE(SA.Admission_Status,  'Pending')  AS Admission_Status
FROM   STUDENT          S
LEFT JOIN SEAT_ALLOCATION  SA  ON SA.Student_ID  = S.Student_ID
                               AND SA.Allocation_Status <> 'Withdrawn'
LEFT JOIN SEAT_MATRIX      SM  ON SM.Seat_ID     = SA.Seat_ID
LEFT JOIN PROGRAM          P   ON P.Program_ID   = SM.Program_ID
LEFT JOIN INSTITUTE        I   ON I.Institute_ID = P.Institute_ID
ORDER  BY S.JEE_Rank ASC
LIMIT  10;  -- Change to desired N

-- ------------------------------------------------------------
-- 6.2  Allocation result for a specific student
--      Replace the Student_ID value (e.g. 1) as needed.
-- ------------------------------------------------------------
SELECT
    S.Student_ID,
    S.Name,
    S.Email,
    S.Mobile_No,
    S.Gender,
    S.Category,
    S.JEE_Rank,
    P.Program_Name,
    P.Degree,
    I.Institute_Name,
    I.Location,
    SM.Category         AS Seat_Category,
    SA.Allocation_Status,
    SA.Admission_Status,
    SA.Allocation_Date
FROM   STUDENT          S
LEFT JOIN SEAT_ALLOCATION  SA  ON SA.Student_ID  = S.Student_ID
                               AND SA.Allocation_Status <> 'Withdrawn'
LEFT JOIN SEAT_MATRIX      SM  ON SM.Seat_ID     = SA.Seat_ID
LEFT JOIN PROGRAM          P   ON P.Program_ID   = SM.Program_ID
LEFT JOIN INSTITUTE        I   ON I.Institute_ID = P.Institute_ID
WHERE  S.Student_ID = 1;   -- ← Replace with actual Student_ID

-- ------------------------------------------------------------
-- 6.3  Remaining (available) seats in all programs,
--      broken down by category
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    P.Program_Name,
    P.Degree,
    SM.Category,
    SM.Total_Seats,
    SM.Filled_Seats,
    SM.Available_Seats,
    CASE
        WHEN SM.Available_Seats = 0 THEN 'FULL'
        ELSE CONCAT(SM.Available_Seats, ' seats left')
    END  AS Status_Label
FROM   SEAT_MATRIX  SM
JOIN   PROGRAM      P   ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE    I   ON I.Institute_ID = P.Institute_ID
ORDER  BY SM.Available_Seats ASC, I.Institute_Name, SM.Category;

-- ------------------------------------------------------------
-- 6.4  Cutoff rank per program and category
--      Shows the worst rank that was actually allocated
--      (effective cutoff) alongside the stored Cutoff_Rank.
-- ------------------------------------------------------------
SELECT
    I.Institute_Name,
    P.Program_Name,
    P.Degree,
    SM.Category,
    SM.Cutoff_Rank                      AS Declared_Cutoff,
    MAX(S.JEE_Rank)                     AS Effective_Cutoff,  -- worst rank allocated
    MIN(S.JEE_Rank)                     AS Topper_Rank        -- best rank allocated
FROM   SEAT_MATRIX      SM
JOIN   PROGRAM          P    ON P.Program_ID   = SM.Program_ID
JOIN   INSTITUTE        I    ON I.Institute_ID = P.Institute_ID
LEFT JOIN SEAT_ALLOCATION SA ON  SA.Seat_ID          = SM.Seat_ID
                             AND SA.Allocation_Status <> 'Withdrawn'
LEFT JOIN STUDENT         S  ON  S.Student_ID = SA.Student_ID
GROUP  BY
    I.Institute_Name, P.Program_Name,
    P.Degree, SM.Category, SM.Cutoff_Rank
ORDER  BY I.Institute_Name, P.Program_Name, SM.Category;

-- ------------------------------------------------------------
-- 6.5  Allocation history from the audit log
--      Full trail of every status change for transparency.
-- ------------------------------------------------------------
SELECT
    SA.Allocation_ID,
    S.Name              AS Student_Name,
    S.JEE_Rank,
    P.Program_Name,
    SM.Category,
    SA.Allocation_Status,
    SA.Admission_Status,
    SA.Allocation_Date  AS Changed_At
FROM   SEAT_ALLOCATION  SA
LEFT JOIN STUDENT       S   ON S.Student_ID  = SA.Student_ID
LEFT JOIN SEAT_MATRIX   SM  ON SM.Seat_ID    = SA.Seat_ID
LEFT JOIN PROGRAM       P   ON P.Program_ID  = SM.Program_ID
ORDER  BY SA.Allocation_Date DESC;

-- ------------------------------------------------------------
-- 6.6  Students eligible for upgrade in the next round
--      Definition: allocated but their first-preference choice
--      is still Active (meaning a better seat may open up).
-- ------------------------------------------------------------
SELECT
    S.Student_ID,
    S.Name,
    S.JEE_Rank,
    S.Category,
    current_prog.Program_Name       AS Current_Program,
    current_inst.Institute_Name     AS Current_Institute,
    top_choice.Program_Name         AS Top_Choice_Program,
    top_inst.Institute_Name         AS Top_Choice_Institute
FROM   STUDENT          S
JOIN   SEAT_ALLOCATION  SA  ON SA.Student_ID  = S.Student_ID
                            AND SA.Allocation_Status <> 'Withdrawn'
JOIN   SEAT_MATRIX      SM  ON SM.Seat_ID     = SA.Seat_ID
JOIN   PROGRAM          current_prog
                            ON current_prog.Program_ID = SM.Program_ID
JOIN   INSTITUTE        current_inst
                            ON current_inst.Institute_ID = current_prog.Institute_ID
-- Find this student's top-preference choice that is still Active
JOIN   CHOICE           C   ON C.Student_ID      = S.Student_ID
                            AND C.Status          = 'Active'
                            AND C.Preference_Order = (
                                    SELECT MIN(C2.Preference_Order)
                                    FROM   CHOICE C2
                                    WHERE  C2.Student_ID = S.Student_ID
                                      AND  C2.Status     = 'Active'
                                )
JOIN   PROGRAM          top_choice
                            ON top_choice.Program_ID = C.Program_ID
JOIN   INSTITUTE        top_inst
                            ON top_inst.Institute_ID = top_choice.Institute_ID
-- Only include students whose top active choice differs from their current seat
WHERE  top_choice.Program_ID <> current_prog.Program_ID
ORDER  BY S.JEE_Rank;

-- ------------------------------------------------------------
-- 6.7  Institute-level summary: programs, seats, fill rate
-- ------------------------------------------------------------
SELECT
    I.Institute_ID,
    I.Institute_Name,
    I.Institute_Type,
    I.Location,
    COUNT(DISTINCT P.Program_ID)    AS Total_Programs,
    SUM(SM.Total_Seats)             AS Total_Seats,
    SUM(SM.Filled_Seats)            AS Filled_Seats,
    SUM(SM.Available_Seats)         AS Available_Seats,
    ROUND(
        100.0 * SUM(SM.Filled_Seats) / NULLIF(SUM(SM.Total_Seats), 0),
        2
    )                               AS Overall_Fill_Pct
FROM   INSTITUTE    I
JOIN   PROGRAM      P   ON P.Institute_ID = I.Institute_ID
JOIN   SEAT_MATRIX  SM  ON SM.Program_ID  = P.Program_ID
GROUP  BY
    I.Institute_ID, I.Institute_Name,
    I.Institute_Type, I.Location
ORDER  BY Overall_Fill_Pct DESC;

-- ------------------------------------------------------------
-- 6.8  Gender-wise and category-wise allocation breakdown
--      Useful for reporting fairness and diversity metrics.
-- ------------------------------------------------------------
SELECT
    S.Gender,
    S.Category,
    COUNT(SA.Allocation_ID)     AS Total_Allocated,
    MIN(S.JEE_Rank)             AS Best_Rank,
    MAX(S.JEE_Rank)             AS Worst_Rank,
    ROUND(AVG(S.JEE_Rank), 0)  AS Avg_Rank
FROM   SEAT_ALLOCATION  SA
JOIN   STUDENT          S  ON S.Student_ID = SA.Student_ID
WHERE  SA.Allocation_Status <> 'Withdrawn'
GROUP  BY S.Gender, S.Category
ORDER  BY S.Gender, S.Category;
