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
-- Reason: Admin pre-loads all institutes before counselling
--         begins. This data does not come from users.
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
-- Reason: Admin pre-loads all programs offered by institutes.
--         Not created by users at any point.
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
-- Reason: Admin sets the category-wise seat matrix before
--         Round 1 begins. Filled_Seats starts at 0.
--         Available_Seats is auto-computed (generated column).
-- Note:   IITs have all 5 categories, NITs have 4,
--         IIITs have 3, Private has 2 — kept realistic.
-- Count:  76 rows
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
-- Reason: Pre-imported from NTA (JEE authority) before the
--         portal opens. Students cannot modify this table.
-- IMPORTANT: ALL entries have Is_Used = FALSE here.
--   Trigger 1 checks Is_Used = FALSE before allowing insert.
--   Trigger 2 sets Is_Used = TRUE automatically after insert.
--   Never manually set TRUE in seed — it will block inserts.
-- Count: 25 entries
--   20 → for seeded students (Trigger 2 marks them TRUE)
--    5 → extra students who qualified but never registered
--        (these stay FALSE permanently — good demo case)
-- ============================================================

INSERT INTO JEE_RANK_VERIFY (JEE_Rank, Year, Roll_No, Name, Category, Is_Used) VALUES
-- Ranks for seeded students (Trigger 2 auto-marks TRUE after STUDENT insert)
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
-- Extra entries — qualified but never registered (stay FALSE permanently)
(300,   2025, 'JEE25021', 'Amrita Desai',        'General', FALSE),
(1500,  2025, 'JEE25022', 'Pranav Kulkarni',     'OBC',     FALSE),
(8000,  2025, 'JEE25023', 'Geeta Pillai',        'SC',      FALSE),
(14000, 2025, 'JEE25024', 'Sameer Qureshi',      'EWS',     FALSE),
(28000, 2025, 'JEE25025', 'Bindu Thomas',        'ST',      FALSE);

-- ============================================================
-- TABLE 5: STUDENT  [PARTIALLY SEEDED]
-- Reason: In the real app students register via the portal.
--         We seed 20 students to demo queries and allocation.
-- Note:   Trigger 1 validates rank + Is_Used = FALSE.
--         Trigger 2 marks Is_Used = TRUE after each insert.
-- Count: 20 students covering all 5 categories + edge case
-- ============================================================

INSERT INTO STUDENT (Name, Email, Mobile_No, Date_of_Birth, Gender, Category, JEE_Rank, Year) VALUES
-- General category
('Arjun Sharma',        'arjun.sharma@gmail.com',   '9876543201', '2005-03-15', 'M', 'General', 85,    2025),
('Priya Nair',          'priya.nair@gmail.com',     '9876543202', '2005-07-22', 'F', 'General', 210,   2025),
('Sneha Iyer',          'sneha.iyer@gmail.com',     '9876543204', '2005-01-10', 'F', 'General', 780,   2025),
('Karthik Menon',       'karthik.menon@gmail.com',  '9876543207', '2004-11-05', 'M', 'General', 2200,  2025),
('Rahul Gupta',         'rahul.gupta@gmail.com',    '9876543211', '2005-04-18', 'M', 'General', 5100,  2025),
('Tanya Verma',         'tanya.verma@gmail.com',    '9876543216', '2005-09-25', 'F', 'General', 13500, 2025),
-- OBC category
('Rohit Mehta',         'rohit.mehta@gmail.com',    '9876543203', '2004-12-30', 'M', 'OBC',     430,   2025),
('Vikram Singh',        'vikram.singh@gmail.com',   '9876543205', '2005-06-14', 'M', 'OBC',     1100,  2025),
('Aditya Kumar',        'aditya.kumar@gmail.com',   '9876543209', '2005-02-28', 'M', 'OBC',     3500,  2025),
('Siddharth Rao',       'siddharth.rao@gmail.com',  '9876543213', '2004-08-17', 'M', 'OBC',     7800,  2025),
('Harish Nambiar',      'harish.nambiar@gmail.com', '9876543217', '2005-05-03', 'M', 'OBC',     16000, 2025),
-- SC category
('Ananya Reddy',        'ananya.reddy@gmail.com',   '9876543206', '2005-10-08', 'F', 'SC',      1350,  2025),
('Meera Krishnan',      'meera.krishnan@gmail.com', '9876543210', '2004-07-12', 'F', 'SC',      4200,  2025),
('Lakshmi Subramaniam', 'lakshmi.sub@gmail.com',    '9876543214', '2005-03-27', 'F', 'SC',      9500,  2025),
('Sunita Yadav',        'sunita.yadav@gmail.com',   '9876543218', '2004-12-09', 'F', 'SC',      19000, 2025),
-- EWS category
('Divya Patel',         'divya.patel@gmail.com',    '9876543208', '2005-08-19', 'F', 'EWS',     2800,  2025),
('Pooja Joshi',         'pooja.joshi@gmail.com',    '9876543212', '2004-06-23', 'F', 'EWS',     6300,  2025),
('Deepak Tiwari',       'deepak.tiwari@gmail.com',  '9876543219', '2005-01-31', 'M', 'EWS',     23000, 2025),
-- ST category
('Nikhil Bose',         'nikhil.bose@gmail.com',    '9876543215', '2004-09-04', 'M', 'ST',      11000, 2025),
-- Edge case: rank too high for any choice (demos unallocated scenario)
('Farhan Sheikh',       'farhan.sheikh@gmail.com',  '9876543220', '2005-05-20', 'M', 'General', 50000, 2025);

-- ============================================================
-- TABLE 6: CHOICE  [PARTIALLY SEEDED]
-- Reason: Students fill choices via portal. We seed choices
--         for all 20 students to make AllocateSeats() demo-ready.
-- Note:   Farhan (rank 50000) picks programs whose cutoffs
--         he cannot meet — demonstrates unallocated edge case.
-- Count: 60 rows (3 choices per student)
-- ============================================================

INSERT INTO CHOICE (Student_ID, Program_ID, Preference_Order) VALUES
-- Arjun Sharma (rank 85, General)
(1, 1, 1),   -- IIT Bombay CSE  (cutoff 100)
(1, 4, 2),   -- IIT Delhi CSE   (cutoff 120)
(1, 7, 3),   -- IIT Madras CSE  (cutoff 150)
-- Priya Nair (rank 210, General)
(2, 4, 1),   -- IIT Delhi CSE   (cutoff 120)
(2, 7, 2),   -- IIT Madras CSE  (cutoff 150)
(2, 1, 3),   -- IIT Bombay CSE  (cutoff 100)
-- Sneha Iyer (rank 780, General)
(3, 2, 1),   -- IIT Bombay EE   (cutoff 200)
(3, 5, 2),   -- IIT Delhi Civil (cutoff 800)
(3, 9, 3),   -- NIT Trichy CSE  (cutoff 2000)
-- Karthik Menon (rank 2200, General)
(4, 9,  1),  -- NIT Trichy CSE    (cutoff 2000)
(4, 12, 2),  -- NIT Warangal CSE  (cutoff 2500)
(4, 14, 3),  -- NIT Calicut CSE   (cutoff 3000)
-- Rahul Gupta (rank 5100, General)
(5, 12, 1),  -- NIT Warangal CSE  (cutoff 2500)
(5, 14, 2),  -- NIT Calicut CSE   (cutoff 3000)
(5, 16, 3),  -- IIIT Hyd CSE      (cutoff 4000)
-- Tanya Verma (rank 13500, General)
(6, 18, 1),  -- VIT CSE           (cutoff 15000)
(6, 16, 2),  -- IIIT Hyd CSE      (cutoff 4000)
(6, 14, 3),  -- NIT Calicut CSE   (cutoff 3000)
-- Rohit Mehta (rank 430, OBC)
(7, 1, 1),   -- IIT Bombay CSE  (OBC cutoff 350)
(7, 4, 2),   -- IIT Delhi CSE   (OBC cutoff 400)
(7, 7, 3),   -- IIT Madras CSE  (OBC cutoff 450)
-- Vikram Singh (rank 1100, OBC)
(8, 7,  1),  -- IIT Madras CSE    (OBC cutoff 450)
(8, 9,  2),  -- NIT Trichy CSE    (OBC cutoff 5000)
(8, 12, 3),  -- NIT Warangal CSE  (OBC cutoff 6000)
-- Aditya Kumar (rank 3500, OBC)
(9, 9,  1),  -- NIT Trichy CSE    (OBC cutoff 5000)
(9, 10, 2),  -- NIT Trichy ECE    (OBC cutoff 7000)
(9, 12, 3),  -- NIT Warangal CSE  (OBC cutoff 6000)
-- Siddharth Rao (rank 7800, OBC)
(10, 13, 1), -- NIT Warangal EEE  (OBC cutoff 9000)
(10, 15, 2), -- NIT Calicut Civil (OBC cutoff 18000)
(10, 17, 3), -- IIIT Hyd ECE      (OBC cutoff 13000)
-- Harish Nambiar (rank 16000, OBC)
(11, 18, 1), -- VIT CSE           (OBC cutoff 35000)
(11, 17, 2), -- IIIT Hyd ECE      (OBC cutoff 13000)
(11, 19, 3), -- VIT ME            (OBC cutoff 55000)
-- Ananya Reddy (rank 1350, SC)
(12, 1, 1),  -- IIT Bombay CSE  (SC cutoff 1200)
(12, 4, 2),  -- IIT Delhi CSE   (SC cutoff 1500)
(12, 7, 3),  -- IIT Madras CSE  (SC cutoff 1800)
-- Meera Krishnan (rank 4200, SC)
(13, 9,  1), -- NIT Trichy CSE    (SC cutoff 12000)
(13, 12, 2), -- NIT Warangal CSE  (SC cutoff 14000)
(13, 16, 3), -- IIIT Hyd CSE      (SC cutoff 20000)
-- Lakshmi Subramaniam (rank 9500, SC)
(14, 14, 1), -- NIT Calicut CSE   (SC cutoff 16000)
(14, 16, 2), -- IIIT Hyd CSE      (SC cutoff 20000)
(14, 18, 3), -- VIT CSE           (General — SC not offered here)
-- Sunita Yadav (rank 19000, SC)
(15, 18, 1), -- VIT CSE
(15, 19, 2), -- VIT ME
(15, 20, 3), -- VIT Biotech
-- Divya Patel (rank 2800, EWS)
(16, 7,  1), -- IIT Madras CSE    (EWS cutoff 300)
(16, 9,  2), -- NIT Trichy CSE    (EWS cutoff 3500)
(16, 12, 3), -- NIT Warangal CSE  (EWS cutoff 4000)
-- Pooja Joshi (rank 6300, EWS)
(17, 14, 1), -- NIT Calicut CSE   (EWS cutoff 5000)
(17, 12, 2), -- NIT Warangal CSE  (EWS cutoff 4000)
(17, 18, 3), -- VIT CSE
-- Deepak Tiwari (rank 23000, EWS)
(18, 18, 1), -- VIT CSE
(18, 19, 2), -- VIT ME
(18, 20, 3), -- VIT Biotech
-- Nikhil Bose (rank 11000, ST)
(19, 3, 1),  -- IIT Bombay ME      (ST cutoff 6000)
(19, 6, 2),  -- IIT Delhi Chemical (ST cutoff 10000)
(19, 8, 3),  -- IIT Madras Aero    (ST cutoff 12000)
-- Farhan Sheikh (rank 50000, General) — won't qualify for any
(20, 1, 1),  -- IIT Bombay CSE  (cutoff 100  — rank 50000, blocked)
(20, 4, 2),  -- IIT Delhi CSE   (cutoff 120  — rank 50000, blocked)
(20, 7, 3);  -- IIT Madras CSE  (cutoff 150  — rank 50000, blocked)

-- ============================================================
-- TABLE 7: USERS  [PARTIALLY SEEDED]
-- Reason: Admin and College accounts are pre-created before
--         the portal goes live. Student accounts are created
--         during registration — we seed 20 demo accounts.
-- Count: 1 Admin + 8 College + 20 Student = 29 users
-- Password_Hash: placeholder bcrypt hash of 'Password@123'
--   Replace with real hashes generated by your Node.js app.
-- ============================================================

-- Admin account (1)
INSERT INTO USERS (Email, Password_Hash, Role, Student_ID, Institute_ID) VALUES
('admin@jeeadmission.in', '$2b$10$dummyhashforadminaccount00001', 'Admin', NULL, NULL);

-- College accounts — one per institute (8)
INSERT INTO USERS (Email, Password_Hash, Role, Student_ID, Institute_ID) VALUES
('admissions@iitb.ac.in', '$2b$10$dummyhashforcollegeaccount001', 'College', NULL, 1),
('admissions@iitd.ac.in', '$2b$10$dummyhashforcollegeaccount002', 'College', NULL, 2),
('admissions@iitm.ac.in', '$2b$10$dummyhashforcollegeaccount003', 'College', NULL, 3),
('admissions@nitt.edu',   '$2b$10$dummyhashforcollegeaccount004', 'College', NULL, 4),
('admissions@nitw.ac.in', '$2b$10$dummyhashforcollegeaccount005', 'College', NULL, 5),
('admissions@nitc.ac.in', '$2b$10$dummyhashforcollegeaccount006', 'College', NULL, 6),
('admissions@iiit.ac.in', '$2b$10$dummyhashforcollegeaccount007', 'College', NULL, 7),
('admissions@vit.ac.in',  '$2b$10$dummyhashforcollegeaccount008', 'College', NULL, 8);

-- Student accounts — one per seeded student (20)
INSERT INTO USERS (Email, Password_Hash, Role, Student_ID, Institute_ID) VALUES
('arjun.sharma@gmail.com',   '$2b$10$dummyhashforstudentaccount001', 'Student', 1,  NULL),
('priya.nair@gmail.com',     '$2b$10$dummyhashforstudentaccount002', 'Student', 2,  NULL),
('sneha.iyer@gmail.com',     '$2b$10$dummyhashforstudentaccount003', 'Student', 3,  NULL),
('karthik.menon@gmail.com',  '$2b$10$dummyhashforstudentaccount004', 'Student', 4,  NULL),
('rahul.gupta@gmail.com',    '$2b$10$dummyhashforstudentaccount005', 'Student', 5,  NULL),
('tanya.verma@gmail.com',    '$2b$10$dummyhashforstudentaccount006', 'Student', 6,  NULL),
('rohit.mehta@gmail.com',    '$2b$10$dummyhashforstudentaccount007', 'Student', 7,  NULL),
('vikram.singh@gmail.com',   '$2b$10$dummyhashforstudentaccount008', 'Student', 8,  NULL),
('aditya.kumar@gmail.com',   '$2b$10$dummyhashforstudentaccount009', 'Student', 9,  NULL),
('siddharth.rao@gmail.com',  '$2b$10$dummyhashforstudentaccount010', 'Student', 10, NULL),
('harish.nambiar@gmail.com', '$2b$10$dummyhashforstudentaccount011', 'Student', 11, NULL),
('ananya.reddy@gmail.com',   '$2b$10$dummyhashforstudentaccount012', 'Student', 12, NULL),
('meera.krishnan@gmail.com', '$2b$10$dummyhashforstudentaccount013', 'Student', 13, NULL),
('lakshmi.sub@gmail.com',    '$2b$10$dummyhashforstudentaccount014', 'Student', 14, NULL),
('sunita.yadav@gmail.com',   '$2b$10$dummyhashforstudentaccount015', 'Student', 15, NULL),
('divya.patel@gmail.com',    '$2b$10$dummyhashforstudentaccount016', 'Student', 16, NULL),
('pooja.joshi@gmail.com',    '$2b$10$dummyhashforstudentaccount017', 'Student', 17, NULL),
('deepak.tiwari@gmail.com',  '$2b$10$dummyhashforstudentaccount018', 'Student', 18, NULL),
('nikhil.bose@gmail.com',    '$2b$10$dummyhashforstudentaccount019', 'Student', 19, NULL),
('farhan.sheikh@gmail.com',  '$2b$10$dummyhashforstudentaccount020', 'Student', 20, NULL);

-- ============================================================
-- TABLE 8: SEAT_ALLOCATION  [LEFT EMPTY — INTENTIONALLY]
-- Reason: Populated live during demo by running the
--         AllocateSeats() stored procedure.
--         Pre-filling defeats the purpose of showing
--         dynamic allocation logic in action.
-- ============================================================

-- No inserts here. Run AllocateSeats() during the demo.