-- ============================================================
-- seed.sql — Sample data for distributed-seat-allocation-system
--
-- TABLE STATUS SUMMARY:
--   FULLY SEEDED     → INSTITUTE, PROGRAM, SEAT_MATRIX, JEE_RANK_VERIFY
--   PARTIALLY SEEDED → STUDENT, CHOICE, USERS
--   LEFT EMPTY       → SEAT_ALLOCATION, ALLOCATION_AUDIT
--
-- IMPORTANT — Run order on a fresh database:
--   schema.sql → triggers.sql → seed.sql
--
-- WHY Is_Used = FALSE for all JEE_RANK_VERIFY entries:
--   Trigger 1 (trg_verify_rank_before_student_insert) checks
--   that Is_Used = FALSE before allowing student registration.
--   Trigger 2 (trg_mark_rank_used_after_student_insert) then
--   sets Is_Used = TRUE automatically after each insert.
--   So we never manually set Is_Used = TRUE here.
--   The 5 extra unused entries stay FALSE permanently
--   (they represent students who qualified but never registered).
--
-- Insertion order follows FK dependencies:
--   INSTITUTE → PROGRAM → SEAT_MATRIX
--   JEE_RANK_VERIFY (standalone)
--   STUDENT → CHOICE
--   USERS (references STUDENT + INSTITUTE)
--   SEAT_ALLOCATION (empty — populated live via AllocateSeats())
-- ============================================================

-- ============================================================
-- TABLE 1: INSTITUTE  [FULLY SEEDED]
-- Count: 8 institutes (3 IIT, 3 NIT, 1 IIIT, 1 Private)
-- ============================================================

INSERT INTO INSTITUTE (Institute_Name, Location, Institute_Type, Contact_No, Email) VALUES
('Indian Institute of Technology Bombay',     'Mumbai, Maharashtra',  'IIT',     '022-25722545', 'admissions@iitb.ac.in'),
('Indian Institute of Technology Delhi',      'New Delhi, Delhi',     'IIT',     '011-26591749', 'admissions@iitd.ac.in'),
('Indian Institute of Technology Madras',     'Chennai, Tamil Nadu',  'IIT',     '044-22578200', 'admissions@iitm.ac.in'),
('National Institute of Technology Trichy',   'Tiruchirappalli, TN',  'NIT',     '0431-2503000', 'admissions@nitt.edu'),
('National Institute of Technology Warangal', 'Warangal, Telangana',  'NIT',     '0870-2462020', 'admissions@nitw.ac.in'),
('National Institute of Technology Calicut',  'Kozhikode, Kerala',    'NIT',     '0495-2286106', 'admissions@nitc.ac.in'),
('IIIT Hyderabad',                            'Hyderabad, Telangana', 'IIIT',    '040-66531000', 'admissions@iiit.ac.in'),
('Vellore Institute of Technology',           'Vellore, Tamil Nadu',  'Private', '0416-2202020', 'admissions@vit.ac.in');

-- ============================================================
-- TABLE 2: PROGRAM  [FULLY SEEDED]
-- Count: 20 programs (~2-3 per institute)
-- ============================================================

INSERT INTO PROGRAM (Program_Name, Degree, Duration_Years, Institute_ID) VALUES
-- IIT Bombay (Institute_ID = 1)
('Computer Science and Engineering',  'BTech', 4, 1),
('Electrical Engineering',            'BTech', 4, 1),
('Mechanical Engineering',            'BTech', 4, 1),
-- IIT Delhi (Institute_ID = 2)
('Computer Science and Engineering',  'BTech', 4, 2),
('Civil Engineering',                 'BTech', 4, 2),
('Chemical Engineering',              'BTech', 4, 2),
-- IIT Madras (Institute_ID = 3)
('Computer Science and Engineering',  'BTech', 4, 3),
('Aerospace Engineering',             'BTech', 4, 3),
-- NIT Trichy (Institute_ID = 4)
('Computer Science and Engineering',  'BTech', 4, 4),
('Electronics and Communication Eng', 'BTech', 4, 4),
('Mechanical Engineering',            'BTech', 4, 4),
-- NIT Warangal (Institute_ID = 5)
('Computer Science and Engineering',  'BTech', 4, 5),
('Electrical and Electronics Eng',    'BTech', 4, 5),
-- NIT Calicut (Institute_ID = 6)
('Computer Science and Engineering',  'BTech', 4, 6),
('Civil Engineering',                 'BTech', 4, 6),
-- IIIT Hyderabad (Institute_ID = 7)
('Computer Science and Engineering',  'BTech', 4, 7),
('Electronics and Communication Eng', 'BTech', 4, 7),
-- VIT (Institute_ID = 8)
('Computer Science and Engineering',  'BTech', 4, 8),
('Mechanical Engineering',            'BTech', 4, 8),
('Biotechnology',                     'BTech', 4, 8);

-- ============================================================
-- TABLE 3: SEAT_MATRIX  [FULLY SEEDED]
-- Note: IITs → 5 categories, NITs → 4 (no ST), IIITs → 3, Private → 2
-- Count: 76 rows
-- ============================================================

-- IIT Bombay — CSE (Program_ID = 1)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(1, 'General', 30, 100),
(1, 'OBC',     16, 350),
(1, 'SC',       9, 1200),
(1, 'ST',       4, 2500),
(1, 'EWS',      7, 200);

-- IIT Bombay — EE (Program_ID = 2)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(2, 'General', 25, 200),
(2, 'OBC',     13, 600),
(2, 'SC',       7, 2000),
(2, 'ST',       3, 4000),
(2, 'EWS',      6, 400);

-- IIT Bombay — ME (Program_ID = 3)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(3, 'General', 20, 500),
(3, 'OBC',     10, 1200),
(3, 'SC',       6, 3500),
(3, 'ST',       3, 6000),
(3, 'EWS',      5, 900);

-- IIT Delhi — CSE (Program_ID = 4)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(4, 'General', 28, 120),
(4, 'OBC',     15, 400),
(4, 'SC',       8, 1500),
(4, 'ST',       4, 3000),
(4, 'EWS',      7, 250);

-- IIT Delhi — Civil (Program_ID = 5)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(5, 'General', 20, 800),
(5, 'OBC',     10, 2000),
(5, 'SC',       6, 5000),
(5, 'ST',       3, 8000),
(5, 'EWS',      5, 1500);

-- IIT Delhi — Chemical (Program_ID = 6)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(6, 'General', 18, 1000),
(6, 'OBC',      9, 2500),
(6, 'SC',       5, 6000),
(6, 'ST',       2, 10000),
(6, 'EWS',      4, 1800);

-- IIT Madras — CSE (Program_ID = 7)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(7, 'General', 30, 150),
(7, 'OBC',     16, 450),
(7, 'SC',       9, 1800),
(7, 'ST',       4, 3500),
(7, 'EWS',      7, 300);

-- IIT Madras — Aerospace (Program_ID = 8)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(8, 'General', 15, 1500),
(8, 'OBC',      8, 3500),
(8, 'SC',       4, 8000),
(8, 'ST',       2, 12000),
(8, 'EWS',      3, 2500);

-- NIT Trichy — CSE (Program_ID = 9)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(9, 'General', 40, 2000),
(9, 'OBC',     20, 5000),
(9, 'SC',      12, 12000),
(9, 'EWS',      9, 3500);

-- NIT Trichy — ECE (Program_ID = 10)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(10, 'General', 35, 3000),
(10, 'OBC',     18, 7000),
(10, 'SC',      10, 15000),
(10, 'EWS',      8, 5000);

-- NIT Trichy — ME (Program_ID = 11)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(11, 'General', 30, 5000),
(11, 'OBC',     15, 12000),
(11, 'SC',       8, 20000),
(11, 'EWS',      7, 8000);

-- NIT Warangal — CSE (Program_ID = 12)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(12, 'General', 38, 2500),
(12, 'OBC',     19, 6000),
(12, 'SC',      11, 14000),
(12, 'EWS',      9, 4000);

-- NIT Warangal — EEE (Program_ID = 13)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(13, 'General', 30, 4000),
(13, 'OBC',     15, 9000),
(13, 'SC',       8, 18000),
(13, 'EWS',      7, 6500);

-- NIT Calicut — CSE (Program_ID = 14)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(14, 'General', 35, 3000),
(14, 'OBC',     17, 7000),
(14, 'SC',      10, 16000),
(14, 'EWS',      8, 5000);

-- NIT Calicut — Civil (Program_ID = 15)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(15, 'General', 25, 8000),
(15, 'OBC',     12, 18000),
(15, 'SC',       7, 30000),
(15, 'EWS',      6, 12000);

-- IIIT Hyderabad — CSE (Program_ID = 16)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(16, 'General', 50, 4000),
(16, 'OBC',     25, 9000),
(16, 'SC',      15, 20000);

-- IIIT Hyderabad — ECE (Program_ID = 17)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(17, 'General', 40, 6000),
(17, 'OBC',     20, 13000),
(17, 'SC',      12, 25000);

-- VIT — CSE (Program_ID = 18)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(18, 'General', 120, 15000),
(18, 'OBC',      60, 35000);

-- VIT — ME (Program_ID = 19)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(19, 'General', 80, 25000),
(19, 'OBC',     40, 55000);

-- VIT — Biotech (Program_ID = 20)
INSERT INTO SEAT_MATRIX (Program_ID, Category, Total_Seats, Cutoff_Rank) VALUES
(20, 'General', 60, 40000),
(20, 'OBC',     30, 80000);

-- ============================================================
-- TABLE 4: JEE_RANK_VERIFY  [FULLY SEEDED]
-- ALL entries have Is_Used = FALSE.
-- Trigger 1 checks Is_Used = FALSE before allowing insert.
-- Trigger 2 sets Is_Used = TRUE automatically after insert.
-- Count: 25 entries (20 for seeded students + 5 never registered)
-- ============================================================

INSERT INTO JEE_RANK_VERIFY (JEE_Rank, Year, Roll_No, Name, Category, Is_Used) VALUES
(85,    2025, 'JEE25001', 'Arjun Sharma',       'General', FALSE),
(210,   2025, 'JEE25002', 'Priya Nair',          'General', FALSE),
(430,   2025, 'JEE25003', 'Rohit Mehta',         'OBC',     FALSE),
(780,   2025, 'JEE25004', 'Sneha Iyer',          'General', FALSE),
(1100,  2025, 'JEE25005', 'Vikram Singh',        'OBC',     FALSE),
(1350,  2025, 'JEE25006', 'Ananya Reddy',        'SC',      FALSE),
(2200,  2025, 'JEE25007', 'Karthik Menon',       'General', FALSE),
(2800,  2025, 'JEE25008', 'Divya Patel',         'EWS',     FALSE),
(3500,  2025, 'JEE25009', 'Aditya Kumar',        'OBC',     FALSE),
(4200,  2025, 'JEE25010', 'Meera Krishnan',      'SC',      FALSE),
(5100,  2025, 'JEE25011', 'Rahul Gupta',         'General', FALSE),
(6300,  2025, 'JEE25012', 'Pooja Joshi',         'EWS',     FALSE),
(7800,  2025, 'JEE25013', 'Siddharth Rao',       'OBC',     FALSE),
(9500,  2025, 'JEE25014', 'Lakshmi Subramaniam', 'SC',      FALSE),
(11000, 2025, 'JEE25015', 'Nikhil Bose',         'ST',      FALSE),
(13500, 2025, 'JEE25016', 'Tanya Verma',         'General', FALSE),
(16000, 2025, 'JEE25017', 'Harish Nambiar',      'OBC',     FALSE),
(19000, 2025, 'JEE25018', 'Sunita Yadav',        'SC',      FALSE),
(23000, 2025, 'JEE25019', 'Deepak Tiwari',       'EWS',     FALSE),
(50000, 2025, 'JEE25020', 'Farhan Sheikh',       'General', FALSE),
-- Extra: qualified but never registered (stay FALSE permanently)
(300,   2025, 'JEE25021', 'Amrita Desai',        'General', FALSE),
(1500,  2025, 'JEE25022', 'Pranav Kulkarni',     'OBC',     FALSE),
(8000,  2025, 'JEE25023', 'Geeta Pillai',        'SC',      FALSE),
(14000, 2025, 'JEE25024', 'Sameer Qureshi',      'EWS',     FALSE),
(28000, 2025, 'JEE25025', 'Bindu Thomas',        'ST',      FALSE);

-- ============================================================
-- TABLE 5: STUDENT  [PARTIALLY SEEDED]
-- Trigger 1 validates rank + Is_Used = FALSE on each insert.
-- Trigger 2 marks Is_Used = TRUE after each insert.
-- Count: 20 students (all 5 categories + 1 unallocatable edge case)
-- ============================================================

INSERT INTO STUDENT (Name, Email, Mobile_No, Date_of_Birth, Gender, Category, JEE_Rank, Year) VALUES
-- General
('Arjun Sharma',        'arjun.sharma@gmail.com',   '9876543201', '2005-03-15', 'M', 'General', 85,    2025),
('Priya Nair',          'priya.nair@gmail.com',     '9876543202', '2005-07-22', 'F', 'General', 210,   2025),
('Sneha Iyer',          'sneha.iyer@gmail.com',     '9876543204', '2005-01-10', 'F', 'General', 780,   2025),
('Karthik Menon',       'karthik.menon@gmail.com',  '9876543207', '2004-11-05', 'M', 'General', 2200,  2025),
('Rahul Gupta',         'rahul.gupta@gmail.com',    '9876543211', '2005-04-18', 'M', 'General', 5100,  2025),
('Tanya Verma',         'tanya.verma@gmail.com',    '9876543216', '2005-09-25', 'F', 'General', 13500, 2025),
-- OBC
('Rohit Mehta',         'rohit.mehta@gmail.com',    '9876543203', '2004-12-30', 'M', 'OBC',     430,   2025),
('Vikram Singh',        'vikram.singh@gmail.com',   '9876543205', '2005-06-14', 'M', 'OBC',     1100,  2025),
('Aditya Kumar',        'aditya.kumar@gmail.com',   '9876543209', '2005-02-28', 'M', 'OBC',     3500,  2025),
('Siddharth Rao',       'siddharth.rao@gmail.com',  '9876543213', '2004-08-17', 'M', 'OBC',     7800,  2025),
('Harish Nambiar',      'harish.nambiar@gmail.com', '9876543217', '2005-05-03', 'M', 'OBC',     16000, 2025),
-- SC
('Ananya Reddy',        'ananya.reddy@gmail.com',   '9876543206', '2005-10-08', 'F', 'SC',      1350,  2025),
('Meera Krishnan',      'meera.krishnan@gmail.com', '9876543210', '2004-07-12', 'F', 'SC',      4200,  2025),
('Lakshmi Subramaniam', 'lakshmi.sub@gmail.com',    '9876543214', '2005-03-27', 'F', 'SC',      9500,  2025),
('Sunita Yadav',        'sunita.yadav@gmail.com',   '9876543218', '2004-12-09', 'F', 'SC',      19000, 2025),
-- EWS
('Divya Patel',         'divya.patel@gmail.com',    '9876543208', '2005-08-19', 'F', 'EWS',     2800,  2025),
('Pooja Joshi',         'pooja.joshi@gmail.com',    '9876543212', '2004-06-23', 'F', 'EWS',     6300,  2025),
('Deepak Tiwari',       'deepak.tiwari@gmail.com',  '9876543219', '2005-01-31', 'M', 'EWS',     23000, 2025),
-- ST
('Nikhil Bose',         'nikhil.bose@gmail.com',    '9876543215', '2004-09-04', 'M', 'ST',      11000, 2025),
-- Edge case: rank too high for any choice (demos unallocated scenario)
('Farhan Sheikh',       'farhan.sheikh@gmail.com',  '9876543220', '2005-05-20', 'M', 'General', 50000, 2025);

-- ============================================================
-- TABLE 6: CHOICE  [PARTIALLY SEEDED]
-- 3 choices per student = 60 rows total.
-- Student_IDs are 1–20 in insert order (fresh DB assumed).
--
-- FIX 1 — Lakshmi (SC, rank 9500, Student_ID 14):
--   Original 3rd choice was VIT CSE (Program 18) under SC,
--   but SEAT_MATRIX has no SC row for Program 18.
--   Replaced with IIIT Hyd CSE (Program 16) which has SC cutoff 20000.
--
-- FIX 2 — Divya Patel (EWS, rank 2800, Student_ID 16):
--   All 3 original choices had cutoffs below her rank (300, 3500, 4000).
--   She would have gone unallocated like Farhan — unintentional.
--   Fixed to achievable EWS seats: NIT Trichy EWS (3500), 
--   NIT Calicut EWS (5000), NIT Warangal EWS (4000).
-- ============================================================

INSERT INTO CHOICE (Student_ID, Program_ID, Preference_Order) VALUES
-- Arjun Sharma (rank 85, General) — Student_ID 1
(1, 1, 1),   -- IIT Bombay CSE  (General cutoff 100)
(1, 4, 2),   -- IIT Delhi CSE   (General cutoff 120)
(1, 7, 3),   -- IIT Madras CSE  (General cutoff 150)
-- Priya Nair (rank 210, General) — Student_ID 2
(2, 4, 1),   -- IIT Delhi CSE   (General cutoff 120) — rank 210 > 120, won't get 1st
(2, 7, 2),   -- IIT Madras CSE  (General cutoff 150) — rank 210 > 150, won't get 2nd
(2, 1, 3),   -- IIT Bombay CSE  (General cutoff 100) ✓ rank 210 > 100... 
             -- NOTE: cutoff = closing rank, so rank 210 qualifies if cutoff >= 210
-- Sneha Iyer (rank 780, General) — Student_ID 3
(3, 2, 1),   -- IIT Bombay EE   (General cutoff 200) ✓
(3, 5, 2),   -- IIT Delhi Civil (General cutoff 800) ✓
(3, 9, 3),   -- NIT Trichy CSE  (General cutoff 2000) ✓
-- Karthik Menon (rank 2200, General) — Student_ID 4
(4, 9,  1),  -- NIT Trichy CSE    (General cutoff 2000) ✓
(4, 12, 2),  -- NIT Warangal CSE  (General cutoff 2500) ✓
(4, 14, 3),  -- NIT Calicut CSE   (General cutoff 3000) ✓
-- Rahul Gupta (rank 5100, General) — Student_ID 5
(5, 12, 1),  -- NIT Warangal CSE  (General cutoff 2500) — rank 5100 > 2500, miss
(5, 14, 2),  -- NIT Calicut CSE   (General cutoff 3000) — miss
(5, 16, 3),  -- IIIT Hyd CSE      (General cutoff 4000) — miss
-- Tanya Verma (rank 13500, General) — Student_ID 6
(6, 18, 1),  -- VIT CSE           (General cutoff 15000) ✓
(6, 16, 2),  -- IIIT Hyd CSE      (General cutoff 4000) — miss
(6, 14, 3),  -- NIT Calicut CSE   (General cutoff 3000) — miss
-- Rohit Mehta (rank 430, OBC) — Student_ID 7
(7, 1, 1),   -- IIT Bombay CSE  (OBC cutoff 350) — rank 430 > 350, miss
(7, 4, 2),   -- IIT Delhi CSE   (OBC cutoff 400) — miss
(7, 7, 3),   -- IIT Madras CSE  (OBC cutoff 450) ✓
-- Vikram Singh (rank 1100, OBC) — Student_ID 8
(8, 7,  1),  -- IIT Madras CSE    (OBC cutoff 450) — miss
(8, 9,  2),  -- NIT Trichy CSE    (OBC cutoff 5000) ✓
(8, 12, 3),  -- NIT Warangal CSE  (OBC cutoff 6000) ✓
-- Aditya Kumar (rank 3500, OBC) — Student_ID 9
(9, 9,  1),  -- NIT Trichy CSE    (OBC cutoff 5000) ✓
(9, 10, 2),  -- NIT Trichy ECE    (OBC cutoff 7000) ✓
(9, 12, 3),  -- NIT Warangal CSE  (OBC cutoff 6000) ✓
-- Siddharth Rao (rank 7800, OBC) — Student_ID 10
(10, 13, 1), -- NIT Warangal EEE  (OBC cutoff 9000) ✓
(10, 15, 2), -- NIT Calicut Civil (OBC cutoff 18000) ✓
(10, 17, 3), -- IIIT Hyd ECE      (OBC cutoff 13000) ✓
-- Harish Nambiar (rank 16000, OBC) — Student_ID 11
(11, 18, 1), -- VIT CSE           (OBC cutoff 35000) ✓
(11, 17, 2), -- IIIT Hyd ECE      (OBC cutoff 13000) — miss
(11, 19, 3), -- VIT ME            (OBC cutoff 55000) ✓
-- Ananya Reddy (rank 1350, SC) — Student_ID 12
(12, 1, 1),  -- IIT Bombay CSE  (SC cutoff 1200) — rank 1350 > 1200, miss
(12, 4, 2),  -- IIT Delhi CSE   (SC cutoff 1500) ✓
(12, 7, 3),  -- IIT Madras CSE  (SC cutoff 1800) ✓
-- Meera Krishnan (rank 4200, SC) — Student_ID 13
(13, 9,  1), -- NIT Trichy CSE    (SC cutoff 12000) ✓
(13, 12, 2), -- NIT Warangal CSE  (SC cutoff 14000) ✓
(13, 16, 3), -- IIIT Hyd CSE      (SC cutoff 20000) ✓
-- Lakshmi Subramaniam (rank 9500, SC) — Student_ID 14
-- FIX 1: Was (14, 18, 3) — VIT CSE has no SC seat row in SEAT_MATRIX.
--         Replaced with IIIT Hyd CSE (Program 16, SC cutoff 20000) ✓
(14, 14, 1), -- NIT Calicut CSE   (SC cutoff 16000) ✓
(14, 16, 2), -- IIIT Hyd CSE      (SC cutoff 20000) ✓
(14, 17, 3), -- IIIT Hyd ECE      (SC cutoff 25000) ✓
-- Sunita Yadav (rank 19000, SC) — Student_ID 15
(15, 18, 1), -- VIT CSE           (General/OBC only — SC not in SEAT_MATRIX, won't allocate)
(15, 19, 2), -- VIT ME            (General/OBC only)
(15, 20, 3), -- VIT Biotech       (General/OBC only)
-- Divya Patel (rank 2800, EWS) — Student_ID 16
-- FIX 2: Original choices had cutoffs 300, 3500, 4000 — all unreachable for rank 2800.
--         Replaced with achievable EWS seats.
(16, 9,  1), -- NIT Trichy CSE    (EWS cutoff 3500) ✓
(16, 14, 2), -- NIT Calicut CSE   (EWS cutoff 5000) ✓
(16, 12, 3), -- NIT Warangal CSE  (EWS cutoff 4000) ✓
-- Pooja Joshi (rank 6300, EWS) — Student_ID 17
(17, 14, 1), -- NIT Calicut CSE   (EWS cutoff 5000) — miss
(17, 12, 2), -- NIT Warangal CSE  (EWS cutoff 4000) — miss
(17, 18, 3), -- VIT CSE           (General/OBC only — won't allocate as EWS)
-- Deepak Tiwari (rank 23000, EWS) — Student_ID 18
(18, 18, 1), -- VIT CSE           (General/OBC only)
(18, 19, 2), -- VIT ME            (General/OBC only)
(18, 20, 3), -- VIT Biotech       (General/OBC only)
-- Nikhil Bose (rank 11000, ST) — Student_ID 19
(19, 3, 1),  -- IIT Bombay ME      (ST cutoff 6000) — miss
(19, 6, 2),  -- IIT Delhi Chemical (ST cutoff 10000) — miss
(19, 8, 3),  -- IIT Madras Aero    (ST cutoff 12000) ✓
-- Farhan Sheikh (rank 50000, General) — Student_ID 20
-- Edge case: no choice will succeed (demos unallocated scenario)
(20, 1, 1),  -- IIT Bombay CSE  (General cutoff 100  — rank 50000, blocked)
(20, 4, 2),  -- IIT Delhi CSE   (General cutoff 120  — rank 50000, blocked)
(20, 7, 3);  -- IIT Madras CSE  (General cutoff 150  — rank 50000, blocked)

-- ============================================================
-- TABLE 7: USERS  [PARTIALLY SEEDED]
-- 1 Admin + 8 College + 20 Student = 29 users
-- Password_Hash: placeholder bcrypt hash — replace with real
--   hashes generated by your Node.js app before production.
-- ============================================================

-- Admin (1)
INSERT INTO USERS (Email, Password_Hash, Role, Student_ID, Institute_ID) VALUES
('admin@jeeadmission.in', '$2b$10$wJF3NymH.8/cwFEPqy5NHetvKWSdmt7MwLuq8Y/0pluJthBXDhUjK', 'Admin', NULL, NULL);

-- College — one per institute (8)
INSERT INTO USERS (Email, Password_Hash, Role, Student_ID, Institute_ID) VALUES
('admissions@iitb.ac.in', '$2b$10$Mx.HdgLXmQ9KDYF0s3zo2.wdQNeZwfykLRbBhMJs3uiv/ir0285ES', 'College', NULL, 1),
('admissions@iitd.ac.in', '$2b$10$UJmRM54IZf0qWA88GG8N1.Bu9kbsfC6buwzX5pOIbG0.iFQY0VV.m', 'College', NULL, 2),
('admissions@iitm.ac.in', '$2b$10$GSGZk4aZhqwjYyIC8I/WAu1AQxQjXf4dhmTp6XyzcoN25OaSUsmtK', 'College', NULL, 3),
('admissions@nitt.edu',   '$2b$10$KHvRRmOIEWLsn2mK6FBarOx/Cip1N4mZ3vXtxOlYiyJ4R01vP5ZN2', 'College', NULL, 4),
('admissions@nitw.ac.in', '$2b$10$E95uekuXxxLHUa95qzSUy.8qrjfDFjRCQmg6Oij8OiESHxn9vq2lW', 'College', NULL, 5),
('admissions@nitc.ac.in', '$2b$10$AgOME7HlwLjriANoqxwe0eJCb8JPEvGk3V/Kj.v/dB6emIyp.eg7e', 'College', NULL, 6),
('admissions@iiit.ac.in', '$2b$10$J9ixDkpHWErHniSFwBp2EOm4/F11Q4HlrQTkQuSv.GpzZ9a/bs4EW', 'College', NULL, 7),
('admissions@vit.ac.in',  '$2b$10$DNHhZ4/AwInT9xpsdlxQyO.Y9ag/N9KHUjhZX7PrPi8PHGjkCMWrq', 'College', NULL, 8);

-- Student — one per seeded student (20)
INSERT INTO USERS (Email, Password_Hash, Role, Student_ID, Institute_ID) VALUES
('arjun.sharma@gmail.com',   '$2b$10$cWarY9.N0BqMca/JcPxCQOqIi0amZkmAeCVjlGExXIP0VWScQhdbi', 'Student', 1,  NULL),
('priya.nair@gmail.com',     '$2b$10$dKLX61oldglRTkYufp51TOM9ENmerf9R8kNpgNIIxOEMZBcxVcICm', 'Student', 2,  NULL),
('sneha.iyer@gmail.com',     '$2b$10$EHSLzPCpUsLcpUZoi470fe5PCv1jogprZ7LqWKstDYqwc6042uizG', 'Student', 3,  NULL),
('karthik.menon@gmail.com',  '$2b$10$CSZiO85p7TDW28ddYptYgO8MDjG8aFLHoJIqnnRT6KGwSzrTBTH0.', 'Student', 4,  NULL),
('rahul.gupta@gmail.com',    '$2b$10$qPbYnRNlnmg.B4A9vJ8ZqOXTyUM4t43fwB9VZjCL4ueO5BDL2UUe.', 'Student', 5,  NULL),
('tanya.verma@gmail.com',    '$2b$10$e50zxhhwb54537YNdydexO.gKt/6iqyMTX3zVqp5N.AnSdgwwZ/Eu', 'Student', 6,  NULL),
('rohit.mehta@gmail.com',    '$2b$10$OU1T8pilTJVpzlcjfuZeX.11w6fHyrqXxKAX32NzuF93H1w34QIvy', 'Student', 7,  NULL),
('vikram.singh@gmail.com',   '$2b$10$A3eeLPu2hoSY5OrC9hoD1OCCRbxqJJ2Dp4X9.2i9ctmpnqkArJF8i', 'Student', 8,  NULL),
('aditya.kumar@gmail.com',   '$2b$10$140WXM4eJ0zJtFu759tVZO9a.uH4NQ1AbpSRc7VGAlE228g7f0tLK', 'Student', 9,  NULL),
('siddharth.rao@gmail.com',  '$2b$10$ubrJu0UXG9T2OwYlXva5RuXTdCs.Fm6yagzdDq6wfjZyg0WdR3zRO', 'Student', 10, NULL),
('harish.nambiar@gmail.com', '$2b$10$XE9v3AipsSDFh9xtqI0lLeQS0nD/a.mqPjX4HUVIvYCysSRzuYla.', 'Student', 11, NULL),
('ananya.reddy@gmail.com',   '$2b$10$oWN.AFUCwHQhB1c2z.tGiOLEtCM0y/vHRhbIvoz/V7HYlWjwPw0/C', 'Student', 12, NULL),
('meera.krishnan@gmail.com', '$2b$10$BF6ZKLHI69uIkLL2fQ65F.r/06M3la8HbEgJ7rSUtJcxkFlcn0K.O', 'Student', 13, NULL),
('lakshmi.sub@gmail.com',    '$2b$10$6eAYadqmKKxu4T6YqKwf4u0WcLU6NR1rzcOo23reERtS5Csg0ENui', 'Student', 14, NULL),
('sunita.yadav@gmail.com',   '$2b$10$6TSTfsVIz25gwSBQ1W9Ncuztff7vKhpk6yv6TVnL5bGff1XVFecMW', 'Student', 15, NULL),
('divya.patel@gmail.com',    '$2b$10$owVQCidoX.HwGlD2jjASJucnmAe0CvwJ/Sy1c/N.tsciwTHbzznuS', 'Student', 16, NULL),
('pooja.joshi@gmail.com',    '$2b$10$UOVuowaD/Jz7g3q2yzOFDuMRoY4Wpge/ufXCPlbN4NPJpKyUalglu', 'Student', 17, NULL),
('deepak.tiwari@gmail.com',  '$2b$10$oz.6zdcJzX.7887XG.FDoO53u4ly1BJZDbVa6wexRUdAbxslHupLC', 'Student', 18, NULL),
('nikhil.bose@gmail.com',    '$2b$10$v2dffkby3UGdZGO8YWeJOuiw49SPVdhdWH9tG0AWoF0excggO7i2q', 'Student', 19, NULL),
('farhan.sheikh@gmail.com',  '$2b$10$MYGsSEpNRR67juhSW0GDfeEDUJIlLo7ji1rOVPwK6XeyCsm0NATii', 'Student', 20, NULL);

-- ============================================================
-- TABLE 8: SEAT_ALLOCATION  [LEFT EMPTY — INTENTIONALLY]
-- Populated live during demo by running AllocateSeats().
-- Pre-filling defeats the purpose of showing dynamic allocation.
-- ============================================================