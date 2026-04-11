-- ============================================================
-- Run this SINGLE file in Aiven to create the entire
-- database from scratch. 
-- Safe to run once. IF NOT EXISTS skips creation but does NOT
-- update existing tables.
-- To reset: DROP DATABASE jee_admission_db; then re-run this file.
-- ============================================================
-- TABLE 1: INSTITUTE  
-- ============================================================
CREATE TABLE IF NOT EXISTS INSTITUTE (
    Institute_ID   INT           NOT NULL AUTO_INCREMENT,
    Institute_Name VARCHAR(150)  NOT NULL,
    Location       VARCHAR(100)  NOT NULL,
    Institute_Type ENUM('IIT','NIT','IIIT', 'Private') NOT NULL,
    Contact_No     VARCHAR(15),
    Email          VARCHAR(100)  NOT NULL,

    PRIMARY KEY (Institute_ID),
    UNIQUE KEY uq_institute_email (Email)
) ENGINE=InnoDB
  COMMENT='Engineering institutes participating in JEE counselling';

-- ============================================================
-- TABLE 2: PROGRAM  
-- ============================================================
CREATE TABLE IF NOT EXISTS PROGRAM (
    Program_ID     INT           NOT NULL AUTO_INCREMENT,
    Program_Name   VARCHAR(100)  NOT NULL,
    Degree         ENUM('BTech','MTech','MBA','PhD') NOT NULL,
    Duration_Years TINYINT       NOT NULL DEFAULT 4,
    Institute_ID   INT           NOT NULL,

    PRIMARY KEY (Program_ID),
    UNIQUE KEY uq_program_identity (Institute_ID, Program_Name, Degree),
    INDEX idx_program_institute (Institute_ID),
    CHECK (Duration_Years > 0),
    CONSTRAINT fk_program_institute
        FOREIGN KEY (Institute_ID)
        REFERENCES INSTITUTE(Institute_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Courses offered by each institute';

-- ============================================================
-- TABLE 3: SEAT_MATRIX  
-- ============================================================
CREATE TABLE IF NOT EXISTS SEAT_MATRIX (
    Seat_ID         INT     NOT NULL AUTO_INCREMENT,
    Program_ID      INT     NOT NULL,
    Category        ENUM('General','OBC','SC','ST','EWS') NOT NULL,
    Total_Seats     INT     NOT NULL,
    Filled_Seats    INT     NOT NULL DEFAULT 0,
    Available_Seats INT GENERATED ALWAYS AS (Total_Seats - Filled_Seats) STORED,
    Cutoff_Rank     INT,

    PRIMARY KEY (Seat_ID),
    UNIQUE KEY uq_program_category (Program_ID, Category),
    INDEX idx_seatmatrix_program (Program_ID),
    CHECK (Total_Seats > 0),
    CHECK (Total_Seats >= Filled_Seats),
    CONSTRAINT fk_seatmatrix_program
        FOREIGN KEY (Program_ID)
        REFERENCES PROGRAM(Program_ID)
        ON DELETE CASCADE,
    CONSTRAINT chk_seat_nonnegative
        CHECK (Filled_Seats >= 0),
    CONSTRAINT chk_cutoff_rank
        CHECK (Cutoff_Rank IS NULL OR Cutoff_Rank > 0)
) ENGINE=InnoDB
  COMMENT='Category-wise seat matrix per program';

-- ============================================================
-- TABLE 4: STUDENT  
-- ============================================================
CREATE TABLE IF NOT EXISTS STUDENT (
    Student_ID    INT           NOT NULL AUTO_INCREMENT,
    Name          VARCHAR(100)  NOT NULL,
    Email         VARCHAR(100)  NOT NULL,
    Mobile_No     VARCHAR(15)   NOT NULL,
    Date_of_Birth DATE          NOT NULL,
    Gender        ENUM('M','F','Other') NOT NULL,
    Category      ENUM('General','OBC','SC','ST','EWS') NOT NULL,
    JEE_Rank          INT           NOT NULL,
    Year          YEAR          NOT NULL,

    PRIMARY KEY (Student_ID),
    UNIQUE KEY uq_student_email (Email, Year),
    UNIQUE KEY uq_student_rank  (JEE_Rank, Year),
    UNIQUE KEY uq_student_mobile (Mobile_No, Year),
    INDEX idx_rank (JEE_Rank),
    CHECK (JEE_Rank > 0)
) ENGINE=InnoDB
  COMMENT='JEE students with rank and category';

-- ============================================================
-- TABLE 5: CHOICE  
-- ============================================================
CREATE TABLE IF NOT EXISTS CHOICE (
    Choice_ID        INT      NOT NULL AUTO_INCREMENT,
    Student_ID       INT      NOT NULL,
    Program_ID       INT      NOT NULL,
    Preference_Order TINYINT  NOT NULL,
    Choice_Date      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status           ENUM('Active','Withdrawn','Allocated') NOT NULL DEFAULT 'Active',

    PRIMARY KEY (Choice_ID),
    UNIQUE KEY uq_student_program (Student_ID, Program_ID),
    UNIQUE KEY uq_student_preference (Student_ID, Preference_Order),
    INDEX idx_choice_student (Student_ID),
    INDEX idx_choice_program (Program_ID),
    CHECK (Preference_Order > 0),
    CONSTRAINT fk_choice_student
        FOREIGN KEY (Student_ID)
        REFERENCES STUDENT(Student_ID)
        ON DELETE CASCADE,
    CONSTRAINT fk_choice_program
        FOREIGN KEY (Program_ID)
        REFERENCES PROGRAM(Program_ID)
        ON DELETE CASCADE
) ENGINE=InnoDB
  COMMENT='Student preference list for counselling';

-- ============================================================
-- TABLE 6: SEAT_ALLOCATION  
-- ============================================================
CREATE TABLE IF NOT EXISTS SEAT_ALLOCATION (
    Allocation_ID     INT      NOT NULL AUTO_INCREMENT,
    Student_ID        INT      NOT NULL,
    Seat_ID           INT      NOT NULL,
    Allocation_Round  TINYINT  NOT NULL,
    Allocation_Status ENUM('Allocated','Upgraded','Rejected','Withdrawn') NOT NULL DEFAULT 'Allocated',
    Allocation_Date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Admission_Status  ENUM('Pending','Confirmed','Cancelled') NOT NULL DEFAULT 'Pending',

    PRIMARY KEY (Allocation_ID),
    UNIQUE KEY uq_student_round (Student_ID, Allocation_Round),
    INDEX idx_alloc_student (Student_ID),
    INDEX idx_alloc_seat (Seat_ID), 
    CHECK (Allocation_Round > 0),
    CONSTRAINT fk_alloc_student
        FOREIGN KEY (Student_ID)
        REFERENCES STUDENT(Student_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_alloc_seat
        FOREIGN KEY (Seat_ID)
        REFERENCES SEAT_MATRIX(Seat_ID)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Final seat allocation results per round';

-- ============================================================
-- TABLE 7: USERS  
-- ============================================================
CREATE TABLE IF NOT EXISTS USERS (
    User_ID       INT           NOT NULL AUTO_INCREMENT,
    Email         VARCHAR(100)  NOT NULL,
    Password_Hash VARCHAR(255)  NOT NULL,
    Role          ENUM('Admin','College','Student') NOT NULL,
    Student_ID    INT           NULL,
    Institute_ID  INT           NULL,

    PRIMARY KEY (User_ID),
    UNIQUE KEY uq_user_email (Email),
    UNIQUE KEY uq_user_student (Student_ID),
    UNIQUE KEY uq_user_institute (Institute_ID),    
    CONSTRAINT fk_user_student
        FOREIGN KEY (Student_ID)
        REFERENCES STUDENT(Student_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_user_institute
        FOREIGN KEY (Institute_ID)
        REFERENCES INSTITUTE(Institute_ID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Login accounts: Admin, College, Student roles';

-- ============================================================
-- TABLE 8: JEE_RANK_VERIFY
-- ============================================================
CREATE TABLE IF NOT EXISTS JEE_RANK_VERIFY (
    Verify_ID    INT  NOT NULL AUTO_INCREMENT,
    JEE_Rank     INT  NOT NULL,
    Year         YEAR NOT NULL,
    Roll_No      VARCHAR(20) NOT NULL,
    Name         VARCHAR(100) NOT NULL,
    Category     ENUM('General','OBC','SC','ST','EWS') NOT NULL,
    Is_Used      BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (Verify_ID),
    UNIQUE KEY uq_rank_year (JEE_Rank, Year),
    UNIQUE KEY uq_roll_year (Roll_No, Year),
    INDEX idx_verify_year (Year)
) ENGINE=InnoDB
  COMMENT='Pre-imported JEE rank data for student registration verification';

-- ============================================================
-- Verify: show all created tables
-- ============================================================
SHOW TABLES;