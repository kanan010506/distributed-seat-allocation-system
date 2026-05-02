-- ============================================================
-- views.sql 
--
-- VIEWS IN THIS FILE:
--   1.  vw_student_allocation        — Full allocation details per student
--   2.  vw_seat_availability         — Live seat counts per program & category
--   3.  vw_program_allocation_summary — Allocated student count per program
--   4.  vw_student_choices           — Student preference list with program info
--   5.  vw_unallocated_students      — Students with no active seat allocation
--   6.  vw_top_rankers               — Students by rank for the latest year
--   7.  vw_cutoff_ranks              — Cutoff rank per program and category
-- ============================================================


-- ============================================================
-- VIEW 1: vw_student_allocation
-- Purpose : One-stop report combining student identity, their
--           allocated seat, program, institute, round, and
--           current allocation + admission status.
-- Useful  : Admin dashboard, student status portal, viva demo.
-- Joins   : STUDENT → SEAT_ALLOCATION → SEAT_MATRIX
--           → PROGRAM → INSTITUTE
-- Sample query:
--   SELECT * FROM vw_student_allocation
--   ORDER BY JEE_Rank;
-- ============================================================
CREATE OR REPLACE VIEW vw_student_allocation AS
SELECT
    st.Student_ID,
    st.Name                  AS Student_Name,
    st.Email                 AS Student_Email,
    st.Gender,
    st.Category,
    st.JEE_Rank,
    st.Year,

    sa.Allocation_ID,
    sa.Allocation_Status,
    sa.Admission_Status,
    sa.Allocation_Date,

    sm.Category              AS Allocated_Category,

    p.Program_ID,
    p.Program_Name,
    p.Degree,

    i.Institute_ID,
    i.Institute_Name,
    i.Location               AS Institute_Location,
    i.Institute_Type

FROM       STUDENT         st
JOIN       SEAT_ALLOCATION sa  ON sa.Student_ID  = st.Student_ID
JOIN       SEAT_MATRIX     sm  ON sm.Seat_ID     = sa.Seat_ID
JOIN       PROGRAM         p   ON p.Program_ID   = sm.Program_ID
JOIN       INSTITUTE       i   ON i.Institute_ID = p.Institute_ID;


-- ============================================================
-- VIEW 2: vw_seat_availability
-- Purpose : Real-time snapshot of total, filled, and available
--           seats for every program-category combination.
--           Available_Seats is a STORED generated column in
--           SEAT_MATRIX so it always reflects the current state.
-- Useful  : Seat availability dashboard, allocation engine.
-- Joins   : SEAT_MATRIX → PROGRAM → INSTITUTE
-- Sample query:
--   SELECT * FROM vw_seat_availability
--   WHERE Available_Seats > 0
--   ORDER BY Institute_Name, Program_Name;
-- ============================================================
CREATE OR REPLACE VIEW vw_seat_availability AS
SELECT
    sm.Seat_ID,
    sm.Category,
    sm.Total_Seats,
    sm.Filled_Seats,
    sm.Available_Seats,
    sm.Cutoff_Rank,

    p.Program_ID,
    p.Program_Name,
    p.Degree,

    i.Institute_ID,
    i.Institute_Name,
    i.Institute_Type,
    i.Location               AS Institute_Location

FROM       SEAT_MATRIX sm
JOIN       PROGRAM     p   ON p.Program_ID   = sm.Program_ID
JOIN       INSTITUTE   i   ON i.Institute_ID = p.Institute_ID;


-- ============================================================
-- VIEW 3: vw_program_allocation_summary
-- Purpose : Count of successfully allocated (non-withdrawn)
--           students per program, along with total and
--           available seats for quick comparison.
-- Useful  : Reporting, counselling round summaries.
-- Joins   : PROGRAM → INSTITUTE → SEAT_MATRIX
--           LEFT JOIN SEAT_ALLOCATION (to count non-withdrawn)
-- Sample query:
--   SELECT * FROM vw_program_allocation_summary
--   ORDER BY Total_Allocated_Students DESC;
-- ============================================================
CREATE OR REPLACE VIEW vw_program_allocation_summary AS
SELECT
    p.Program_ID,
    p.Program_Name,
    p.Degree,
    i.Institute_Name,

    -- Aggregate seat totals across all categories for this program
    SUM(sm.Total_Seats)      AS Total_Seats,
    SUM(sm.Filled_Seats)     AS Total_Filled_Seats,
    SUM(sm.Available_Seats)  AS Total_Available_Seats,

    -- Count only non-withdrawn allocations linked to this program
    COUNT(sa.Allocation_ID)  AS Total_Allocated_Students

FROM       PROGRAM         p
JOIN       INSTITUTE       i   ON i.Institute_ID = p.Institute_ID
JOIN       SEAT_MATRIX     sm  ON sm.Program_ID  = p.Program_ID
LEFT JOIN  SEAT_ALLOCATION sa  ON sa.Seat_ID     = sm.Seat_ID
                               AND sa.Allocation_Status <> 'Withdrawn'

GROUP BY
    p.Program_ID,
    p.Program_Name,
    p.Degree,
    i.Institute_Name;


-- ============================================================
-- VIEW 4: vw_student_choices
-- Purpose : Show every student's preference list with program
--           and institute details.
--           Status column shows whether the choice is Active,
--           Allocated, or Withdrawn.
-- Useful  : Counselling portal, student self-service view.
-- Joins   : STUDENT → CHOICE → PROGRAM → INSTITUTE
-- Sample query:
--   SELECT * FROM vw_student_choices
--   WHERE Student_ID = 101
--   ORDER BY Preference_Order;
-- ============================================================
CREATE OR REPLACE VIEW vw_student_choices AS
SELECT
    st.Student_ID,
    st.Name              AS Student_Name,
    st.JEE_Rank,
    st.Category,
    st.Year,

    c.Choice_ID,
    c.Preference_Order,
    c.Choice_Date,
    c.Status             AS Choice_Status,

    p.Program_ID,
    p.Program_Name,
    p.Degree,

    i.Institute_Name,
    i.Institute_Type,
    i.Location           AS Institute_Location

FROM       STUDENT    st
JOIN       CHOICE     c   ON c.Student_ID   = st.Student_ID
JOIN       PROGRAM    p   ON p.Program_ID   = c.Program_ID
JOIN       INSTITUTE  i   ON i.Institute_ID = p.Institute_ID;


-- ============================================================
-- VIEW 5: vw_unallocated_students
-- Purpose : List all registered students who currently have
--           NO active (non-withdrawn) seat allocation.
--           These are candidates still waiting for a seat.
-- Useful  : Identifying students needing allocation in the
--           next counselling round.
-- Note    : Uses NOT EXISTS for correctness — handles students
--           whose only allocations are all Withdrawn.
-- Sample query:
--   SELECT * FROM vw_unallocated_students
--   ORDER BY JEE_Rank;
-- ============================================================
CREATE OR REPLACE VIEW vw_unallocated_students AS
SELECT
    st.Student_ID,
    st.Name,
    st.Email,
    st.Mobile_No,
    st.Gender,
    st.Category,
    st.JEE_Rank,
    st.Year

FROM STUDENT st
WHERE NOT EXISTS (
    SELECT 1
    FROM   SEAT_ALLOCATION sa
    WHERE  sa.Student_ID        = st.Student_ID
      AND  sa.Allocation_Status <> 'Withdrawn'
);


-- ============================================================
-- VIEW 6: vw_top_rankers
-- Purpose : Students ranked by JEE_Rank for the most recent
--           counselling year in the database, along with their
--           current allocation details (NULL if not yet seated).
--
-- FIX 1   : WHERE clause now placed AFTER all LEFT JOINs.
--           (Previously it split FROM and LEFT JOIN, causing
--           Error Code 1064 syntax error.)
-- FIX 2   : LIMIT removed — LIMIT is not permitted inside a
--           MySQL VIEW definition. Use LIMIT at query time:
--             SELECT * FROM vw_top_rankers
--             ORDER BY JEE_Rank LIMIT 10;
--
-- Useful  : Merit list display, viva demonstration.
-- Sample query (top 10):
--   SELECT * FROM vw_top_rankers
--   ORDER BY JEE_Rank
--   LIMIT 10;
-- ============================================================
CREATE OR REPLACE VIEW vw_top_rankers AS
SELECT
    st.Student_ID,
    st.Name,
    st.JEE_Rank,
    st.Category,
    st.Gender,
    st.Year,

    sa.Allocation_Status,
    sa.Admission_Status,
    p.Program_Name       AS Allocated_Program,
    i.Institute_Name     AS Allocated_Institute

FROM       STUDENT         st
LEFT JOIN  SEAT_ALLOCATION sa  ON sa.Student_ID  = st.Student_ID
                               AND sa.Allocation_Status <> 'Withdrawn'
LEFT JOIN  SEAT_MATRIX     sm  ON sm.Seat_ID     = sa.Seat_ID
LEFT JOIN  PROGRAM         p   ON p.Program_ID   = sm.Program_ID
LEFT JOIN  INSTITUTE       i   ON i.Institute_ID = p.Institute_ID

-- WHERE comes after all JOINs — filters for the latest year only
WHERE st.Year = (SELECT MAX(Year) FROM STUDENT);


-- ============================================================
-- VIEW 7: vw_cutoff_ranks
-- Purpose : Shows the published cutoff rank for each
--           program-category pair. A student whose JEE_Rank
--           is <= Cutoff_Rank is eligible for that seat.
--           Rows with NULL Cutoff_Rank are excluded (not yet set).
-- Useful  : Eligibility checks, counselling guidance, viva.
-- Joins   : SEAT_MATRIX → PROGRAM → INSTITUTE
-- Sample query:
--   SELECT * FROM vw_cutoff_ranks
--   WHERE Category = 'General'
--   ORDER BY Cutoff_Rank;
-- ============================================================
CREATE OR REPLACE VIEW vw_cutoff_ranks AS
SELECT
    sm.Seat_ID,
    sm.Category,
    sm.Cutoff_Rank,
    sm.Total_Seats,
    sm.Available_Seats,

    p.Program_ID,
    p.Program_Name,
    p.Degree,

    i.Institute_ID,
    i.Institute_Name,
    i.Institute_Type,
    i.Location           AS Institute_Location

FROM       SEAT_MATRIX sm
JOIN       PROGRAM     p   ON p.Program_ID   = sm.Program_ID
JOIN       INSTITUTE   i   ON i.Institute_ID = p.Institute_ID

WHERE sm.Cutoff_Rank IS NOT NULL;


-- ============================================================
-- VERIFICATION QUERY
-- Run this after executing the file to confirm all 7 views
-- were created successfully in the current schema.
-- ============================================================
SELECT
    TABLE_NAME   AS View_Name,
    TABLE_SCHEMA AS DB_Name
FROM  INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME;
