-- ============================================================================
-- HOSTEL MANAGEMENT SYSTEM - FULL SCHEMA (Hostel only, no authentication)
-- Safe to run multiple times. Includes tables, sample data, views,
-- 4 triggers (room management), 2 functions, and 8 stored procedures.
-- ============================================================================
CREATE DATABASE IF NOT EXISTS hostel_management;
USE hostel_management;

-- ---------------------------
-- DROP views, triggers, funcs, procs, tables (safe re-run)
-- ---------------------------
DROP VIEW IF EXISTS student_room_view;
DROP VIEW IF EXISTS student_mess_view;
DROP VIEW IF EXISTS warden_student_view;

DROP TRIGGER IF EXISTS trg_fees_before_insert;
DROP TRIGGER IF EXISTS trg_alloc_before_insert;
DROP TRIGGER IF EXISTS trg_alloc_after_insert;
DROP TRIGGER IF EXISTS trg_alloc_after_delete;

DROP FUNCTION IF EXISTS room_available_slots;
DROP FUNCTION IF EXISTS student_total_paid;

DROP PROCEDURE IF EXISTS sp_transfer_student_room;
DROP PROCEDURE IF EXISTS sp_get_student_details;
DROP PROCEDURE IF EXISTS sp_list_available_rooms;
DROP PROCEDURE IF EXISTS sp_change_mess_booking;
DROP PROCEDURE IF EXISTS sp_calculate_student_monthly_charges;
DROP PROCEDURE IF EXISTS sp_get_room_occupants;
DROP PROCEDURE IF EXISTS sp_submit_laundry;
DROP PROCEDURE IF EXISTS sp_generate_hostel_report;

DROP TABLE IF EXISTS monitors;
DROP TABLE IF EXISTS gives_laundry;
DROP TABLE IF EXISTS books_mess;
DROP TABLE IF EXISTS student_room_fees;
DROP TABLE IF EXISTS local_guardian;
DROP TABLE IF EXISTS laundry;
DROP TABLE IF EXISTS mess;
DROP TABLE IF EXISTS fees;
DROP TABLE IF EXISTS room;
DROP TABLE IF EXISTS warden;
DROP TABLE IF EXISTS student;

-- ============================================================================
-- TABLES
-- ============================================================================

-- Student
CREATE TABLE student (
    s_id VARCHAR(20) PRIMARY KEY,
    f_name VARCHAR(50) NOT NULL,
    m_name VARCHAR(50),
    l_name VARCHAR(50) NOT NULL,
    p_no VARCHAR(15) NOT NULL,
    leader_id VARCHAR(20),
    FOREIGN KEY (leader_id) REFERENCES student(s_id) ON DELETE SET NULL
);

-- Local Guardian
CREATE TABLE local_guardian (
    s_id VARCHAR(20),
    name VARCHAR(100) NOT NULL,
    p_no VARCHAR(15) PRIMARY KEY,
    FOREIGN KEY (s_id) REFERENCES student(s_id) ON DELETE CASCADE
);

-- Room
CREATE TABLE room (
    r_no VARCHAR(10) PRIMARY KEY,
    no_of_people INT NOT NULL DEFAULT 0,
    max_capacity INT NOT NULL DEFAULT 4
);

-- Fees
CREATE TABLE fees (
    p_id VARCHAR(30) PRIMARY KEY,
    p_date DATE NOT NULL,
    p_method VARCHAR(20) NOT NULL CHECK (p_method IN ('Cash', 'Card', 'UPI', 'Net Banking')),
    amount DECIMAL(10,2) NOT NULL
);

-- Laundry master (defines laundry package / rate)
CREATE TABLE laundry (
    l_no VARCHAR(20) PRIMARY KEY,
    days_of_laundry INT NOT NULL,
    rate_per_day DECIMAL(10,2) DEFAULT 50.00
);

-- Mess
CREATE TABLE mess (
    m_no VARCHAR(10) PRIMARY KEY,
    m_name VARCHAR(50) NOT NULL,
    monthly_fee DECIMAL(10,2) NOT NULL
);

-- Warden
CREATE TABLE warden (
    w_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    p_no VARCHAR(15) NOT NULL
);

-- Student-Room-Fees (ternary relation)
CREATE TABLE student_room_fees (
    s_id VARCHAR(20),
    r_no VARCHAR(10),
    p_id VARCHAR(30),
    allotment_date DATE NOT NULL,
    PRIMARY KEY (s_id),
    FOREIGN KEY (s_id) REFERENCES student(s_id) ON DELETE CASCADE,
    FOREIGN KEY (r_no) REFERENCES room(r_no) ON DELETE CASCADE,
    FOREIGN KEY (p_id) REFERENCES fees(p_id) ON DELETE CASCADE
);

-- Student-Mess booking
CREATE TABLE books_mess (
    s_id VARCHAR(20),
    m_no VARCHAR(10),
    booking_date DATE NOT NULL,
    PRIMARY KEY (s_id),
    FOREIGN KEY (s_id) REFERENCES student(s_id) ON DELETE CASCADE,
    FOREIGN KEY (m_no) REFERENCES mess(m_no) ON DELETE CASCADE
);

-- Student gives laundry (transactions)
CREATE TABLE gives_laundry (
    s_id VARCHAR(20),
    l_no VARCHAR(20),
    submission_date DATE NOT NULL,
    PRIMARY KEY (s_id, l_no, submission_date),
    FOREIGN KEY (s_id) REFERENCES student(s_id) ON DELETE CASCADE,
    FOREIGN KEY (l_no) REFERENCES laundry(l_no) ON DELETE CASCADE
);

-- Monitors (warden-student mapping)
CREATE TABLE monitors (
    w_id VARCHAR(20),
    s_id VARCHAR(20),
    assigned_date DATE NOT NULL,
    PRIMARY KEY (w_id, s_id),
    FOREIGN KEY (w_id) REFERENCES warden(w_id) ON DELETE CASCADE,
    FOREIGN KEY (s_id) REFERENCES student(s_id) ON DELETE CASCADE
);

-- ============================================================================
-- SAMPLE DATA INSERTS
-- (If you prefer no sample data, remove these INSERT blocks)
-- ============================================================================

-- Wardens
INSERT INTO warden (w_id, name, p_no) VALUES
('W001', 'Dr. Rajesh Kumar', '9876543210'),
('W002', 'Mrs. Priya Sharma', '9876543211'),
('W003', 'Mr. Arun Patel', '9876543212');

-- Rooms
INSERT INTO room (r_no, no_of_people, max_capacity) VALUES
('R101', 0, 4), ('R102', 0, 4), ('R103', 0, 4), ('R104', 0, 4),
('R201', 0, 2), ('R202', 0, 2), ('R203', 0, 2), ('R204', 0, 2),
('R301', 0, 3), ('R302', 0, 3), ('R303', 0, 3), ('R304', 0, 3);

-- Mess
INSERT INTO mess (m_no, m_name, monthly_fee) VALUES
('M01', 'North Mess', 4500.00),
('M02', 'South Mess', 4200.00),
('M03', 'Special Mess', 5000.00);

-- Laundry master
INSERT INTO laundry (l_no, days_of_laundry, rate_per_day) VALUES
('L001', 7, 50.00),
('L002', 3, 30.00),
('L003', 5, 40.00);

-- Students
INSERT INTO student (s_id, f_name, m_name, l_name, p_no, leader_id) VALUES
('PES1UG23CS440', 'PRANEET', 'VASUDEV', 'MAHENDRAKAR', '9123456780', NULL),
('PES1UG23CS461', 'RAGHAVENDRA', NULL, 'N', '9123456781', NULL),
('PES1UG23CS100', 'Amit', 'Kumar', 'Sharma', '9123456782', NULL),
('PES1UG23CS101', 'Sneha', 'Devi', 'Singh', '9123456783', 'PES1UG23CS440'),
('PES1UG23CS102', 'Rahul', NULL, 'Verma', '9123456784', 'PES1UG23CS440'),
('PES1UG23CS103', 'Priya', 'Kumari', 'Reddy', '9123456785', 'PES1UG23CS461');

-- Local Guardians
INSERT INTO local_guardian (s_id, name, p_no) VALUES
('PES1UG23CS440', 'Mr. Vasudev Mahendrakar', '9988776655'),
('PES1UG23CS461', 'Mr. Nagaraj', '9988776656'),
('PES1UG23CS100', 'Mr. Rajesh Sharma', '9988776657'),
('PES1UG23CS101', 'Mrs. Sunita Singh', '9988776658'),
('PES1UG23CS102', 'Mr. Vijay Verma', '9988776659'),
('PES1UG23CS103', 'Mrs. Lakshmi Reddy', '9988776660');

-- Fees
INSERT INTO fees (p_id, p_date, p_method, amount) VALUES
('F001', '2025-01-15', 'UPI', 75000.00),
('F002', '2025-01-16', 'Net Banking', 75000.00),
('F003', '2025-01-17', 'Card', 80000.00),
('F004', '2025-01-18', 'UPI', 75000.00),
('F005', '2025-01-19', 'Cash', 75000.00),
('F006', '2025-01-20', 'UPI', 80000.00);

-- Student-Room-Fee allocations
INSERT INTO student_room_fees (s_id, r_no, p_id, allotment_date) VALUES
('PES1UG23CS440', 'R101', 'F001', '2025-01-15'),
('PES1UG23CS461', 'R101', 'F002', '2025-01-16'),
('PES1UG23CS100', 'R102', 'F003', '2025-01-17'),
('PES1UG23CS101', 'R201', 'F004', '2025-01-18'),
('PES1UG23CS102', 'R201', 'F005', '2025-01-19'),
('PES1UG23CS103', 'R301', 'F006', '2025-01-20');

-- Update room occupancy according to sample allocations
UPDATE room SET no_of_people = 2 WHERE r_no = 'R101';
UPDATE room SET no_of_people = 1 WHERE r_no = 'R102';
UPDATE room SET no_of_people = 2 WHERE r_no = 'R201';
UPDATE room SET no_of_people = 1 WHERE r_no = 'R301';

-- Mess bookings
INSERT INTO books_mess (s_id, m_no, booking_date) VALUES
('PES1UG23CS440', 'M01', '2025-01-15'),
('PES1UG23CS461', 'M01', '2025-01-16'),
('PES1UG23CS100', 'M02', '2025-01-17'),
('PES1UG23CS101', 'M03', '2025-01-18'),
('PES1UG23CS102', 'M02', '2025-01-19'),
('PES1UG23CS103', 'M01', '2025-01-20');

-- Laundry transactions
INSERT INTO gives_laundry (s_id, l_no, submission_date) VALUES
('PES1UG23CS440', 'L001', '2025-01-20'),
('PES1UG23CS461', 'L002', '2025-01-21'),
('PES1UG23CS100', 'L001', '2025-01-22'),
('PES1UG23CS101', 'L003', '2025-01-23');

-- Monitors
INSERT INTO monitors (w_id, s_id, assigned_date) VALUES
('W001', 'PES1UG23CS440', '2025-01-01'),
('W001', 'PES1UG23CS461', '2025-01-01'),
('W001', 'PES1UG23CS100', '2025-01-01'),
('W002', 'PES1UG23CS101', '2025-01-01'),
('W002', 'PES1UG23CS102', '2025-01-01'),
('W003', 'PES1UG23CS103', '2025-01-01');

-- ============================================================================
-- VIEWS
-- ============================================================================
CREATE VIEW student_room_view AS
SELECT 
    s.s_id,
    CONCAT(s.f_name, ' ', IFNULL(s.m_name, ''), ' ', s.l_name) AS full_name,
    s.p_no,
    srf.r_no,
    r.no_of_people,
    f.amount AS fees_paid,
    f.p_method,
    f.p_date
FROM student s
LEFT JOIN student_room_fees srf ON s.s_id = srf.s_id
LEFT JOIN room r ON srf.r_no = r.r_no
LEFT JOIN fees f ON srf.p_id = f.p_id;

CREATE VIEW student_mess_view AS
SELECT 
    s.s_id,
    CONCAT(s.f_name, ' ', IFNULL(s.m_name, ''), ' ', s.l_name) AS full_name,
    m.m_no,
    m.m_name,
    m.monthly_fee,
    bm.booking_date
FROM student s
LEFT JOIN books_mess bm ON s.s_id = bm.s_id
LEFT JOIN mess m ON bm.m_no = m.m_no;

CREATE VIEW warden_student_view AS
SELECT 
    w.w_id,
    w.name AS warden_name,
    w.p_no AS warden_phone,
    s.s_id,
    CONCAT(s.f_name, ' ', IFNULL(s.m_name, ''), ' ', s.l_name) AS student_name,
    mon.assigned_date
FROM warden w
JOIN monitors mon ON w.w_id = mon.w_id
JOIN student s ON mon.s_id = s.s_id;

-- ============================================================================
-- FUNCTIONS, TRIGGERS, PROCEDURES (use DELIMITER to allow semicolons inside)
-- ============================================================================


DELIMITER $$

-- FUNCTION: room_available_slots(r)
CREATE FUNCTION room_available_slots(r VARCHAR(10))
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE cap INT DEFAULT 0;
    DECLARE occ INT DEFAULT 0;
    SELECT IFNULL(max_capacity,0) INTO cap FROM room WHERE r_no = r LIMIT 1;
    SELECT IFNULL(no_of_people,0) INTO occ FROM room WHERE r_no = r LIMIT 1;
    RETURN GREATEST(cap - occ, 0);
END$$

-- FUNCTION: student_total_paid(sid)
CREATE FUNCTION student_total_paid(sid VARCHAR(30))
RETURNS DECIMAL(20,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(20,2) DEFAULT 0;
    SELECT IFNULL(SUM(f.amount),0) INTO total
    FROM student_room_fees srf
    JOIN fees f ON srf.p_id = f.p_id
    WHERE srf.s_id = sid;
    RETURN total;
END$$

-- TRIGGER: fees BEFORE INSERT (validate amount, default p_date)
CREATE TRIGGER trg_fees_before_insert
BEFORE INSERT ON fees
FOR EACH ROW
BEGIN
    IF NEW.amount <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fee amount must be positive';
    END IF;
    IF NEW.p_date IS NULL THEN
        SET NEW.p_date = CURDATE();
    END IF;
END$$

-- TRIGGER: prevent duplicate allocation for the same student
CREATE TRIGGER trg_alloc_before_insert
BEFORE INSERT ON student_room_fees
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM student_room_fees WHERE s_id = NEW.s_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student already allocated to a room';
    END IF;
END$$

-- TRIGGER: after allocation: increment occupancy & enforce capacity
CREATE TRIGGER trg_alloc_after_insert
AFTER INSERT ON student_room_fees
FOR EACH ROW
BEGIN
    UPDATE room
    SET no_of_people = no_of_people + 1
    WHERE r_no = NEW.r_no;

    IF (SELECT no_of_people FROM room WHERE r_no = NEW.r_no) >
       (SELECT max_capacity FROM room WHERE r_no = NEW.r_no) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Room capacity exceeded';
    END IF;
END$$

-- TRIGGER: after delete allocation: decrement occupancy safely
CREATE TRIGGER trg_alloc_after_delete
AFTER DELETE ON student_room_fees
FOR EACH ROW
BEGIN
    UPDATE room
    SET no_of_people = GREATEST(no_of_people - 1, 0)
    WHERE r_no = OLD.r_no;
END$$

DELIMITER $$

-- TRIGGER: after laundry submission → generate fees entry
CREATE TRIGGER trg_laundry_after_insert
AFTER INSERT ON gives_laundry
FOR EACH ROW
BEGIN
    DECLARE laundry_rate DECIMAL(10,2);
    DECLARE short_id VARCHAR(30);

    -- fetch rate
    SELECT rate_per_day INTO laundry_rate
    FROM laundry
    WHERE l_no = NEW.l_no;

    -- short payment ID (fits VARCHAR(30))
    SET short_id = CONCAT('LND-', SUBSTRING(UUID(), 1, 8));

    -- insert revenue entry
    INSERT INTO fees (p_id, p_date, p_method, amount)
    VALUES (short_id, NEW.submission_date, 'Cash', laundry_rate);
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_mess_after_insert
AFTER INSERT ON books_mess
FOR EACH ROW
BEGIN
    DECLARE messfee DECIMAL(10,2);
    DECLARE fid VARCHAR(30);

    -- get fee
    SELECT monthly_fee INTO messfee
    FROM mess
    WHERE m_no = NEW.m_no;

    -- generate fee id
    SET fid = CONCAT('MSS-', SUBSTRING(UUID(), 1, 8));

    -- insert fee
    INSERT INTO fees (p_id, p_date, p_method, amount)
    VALUES (fid, CURDATE(), 'Cash', messfee);
END$$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER trg_mess_after_update
AFTER UPDATE ON books_mess
FOR EACH ROW
BEGIN
    DECLARE messfee DECIMAL(10,2);
    DECLARE fid VARCHAR(30);

    SELECT monthly_fee INTO messfee
    FROM mess
    WHERE m_no = NEW.m_no;

    SET fid = CONCAT('MSS-', SUBSTRING(UUID(), 1, 8));

    INSERT INTO fees (p_id, p_date, p_method, amount)
    VALUES (fid, CURDATE(), 'Cash', messfee);
END$$

DELIMITER ;


-- ============================================================================
-- STORED PROCEDURES (Hostel-related)
-- ============================================================================
-- 1) Transfer student between rooms
CREATE PROCEDURE sp_transfer_student_room(
    IN p_student_id VARCHAR(20),
    IN p_new_room_no VARCHAR(10)
)
BEGIN
    DECLARE old_room VARCHAR(10);
    DECLARE room_capacity INT DEFAULT 0;
    DECLARE current_occupancy INT DEFAULT 0;

    SELECT r_no INTO old_room FROM student_room_fees WHERE s_id = p_student_id LIMIT 1;

    IF old_room IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Student does not have a current room allocation';
    END IF;

    SELECT IFNULL(max_capacity,0), IFNULL(no_of_people,0) INTO room_capacity, current_occupancy
    FROM room WHERE r_no = p_new_room_no LIMIT 1;

    IF current_occupancy >= room_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Target room is full';
    END IF;

    -- Update allocation
    UPDATE student_room_fees
    SET r_no = p_new_room_no, allotment_date = CURDATE()
    WHERE s_id = p_student_id;

    -- adjust counts: decrement old room, increment new room
    UPDATE room SET no_of_people = GREATEST(no_of_people - 1, 0) WHERE r_no = old_room;
    UPDATE room SET no_of_people = no_of_people + 1 WHERE r_no = p_new_room_no;
END$$

-- 2) Get comprehensive student info
CREATE PROCEDURE sp_get_student_details(IN p_student_id VARCHAR(20))
BEGIN
    SELECT s.s_id,
           CONCAT(s.f_name, ' ', IFNULL(s.m_name, ''), ' ', s.l_name) AS full_name,
           s.p_no,
           s.leader_id,
           srf.r_no,
           r.max_capacity,
           r.no_of_people,
           f.p_id, f.amount AS fees_paid, f.p_date, f.p_method,
           m.m_no, m.m_name, m.monthly_fee,
           lg.name AS guardian_name, lg.p_no AS guardian_phone
    FROM student s
    LEFT JOIN student_room_fees srf ON s.s_id = srf.s_id
    LEFT JOIN room r ON srf.r_no = r.r_no
    LEFT JOIN fees f ON srf.p_id = f.p_id
    LEFT JOIN books_mess bm ON s.s_id = bm.s_id
    LEFT JOIN mess m ON bm.m_no = m.m_no
    LEFT JOIN local_guardian lg ON s.s_id = lg.s_id
    WHERE s.s_id = p_student_id;
END$$

-- 3) List rooms with available slots
CREATE PROCEDURE sp_list_available_rooms()
BEGIN
    SELECT r_no, no_of_people, max_capacity,
           (max_capacity - no_of_people) AS available_slots,
           CASE WHEN max_capacity > 0 THEN ROUND((no_of_people / max_capacity) * 100, 2) ELSE 0 END AS occupancy_percentage
    FROM room
    WHERE no_of_people < max_capacity
    ORDER BY available_slots DESC;
END$$

-- 4) Change student's mess booking
CREATE PROCEDURE sp_change_mess_booking(
    IN p_student_id VARCHAR(20),
    IN p_new_mess_no VARCHAR(10)
)
BEGIN
    -- If student has a booking, update; else insert
    IF EXISTS (SELECT 1 FROM books_mess WHERE s_id = p_student_id) THEN
        UPDATE books_mess SET m_no = p_new_mess_no, booking_date = CURDATE() WHERE s_id = p_student_id;
    ELSE
        INSERT INTO books_mess (s_id, m_no, booking_date) VALUES (p_student_id, p_new_mess_no, CURDATE());
    END IF;
END$$

-- 5) Calculate monthly charges for a student (mess + laundry), total paid, balance
CREATE PROCEDURE sp_calculate_student_monthly_charges(
    IN p_student_id VARCHAR(20),
    IN p_month INT,
    IN p_year INT
)
BEGIN
    DECLARE mess_fee DECIMAL(12,2) DEFAULT 0.00;
    DECLARE laundry_charges DECIMAL(12,2) DEFAULT 0.00;
    DECLARE total DECIMAL(12,2) DEFAULT 0.00;
    DECLARE total_paid DECIMAL(12,2) DEFAULT 0.00;

    -- Sum mess fee if student booked a mess in the specified month/year
    SELECT IFNULL(SUM(m.monthly_fee),0) INTO mess_fee
    FROM books_mess bm
    JOIN mess m ON bm.m_no = m.m_no
    WHERE bm.s_id = p_student_id
      AND MONTH(bm.booking_date) = p_month
      AND YEAR(bm.booking_date) = p_year;

    -- Approximate laundry charges: sum rate_per_day for submissions in month/year
    SELECT IFNULL(SUM(l.rate_per_day),0) INTO laundry_charges
    FROM gives_laundry gl
    JOIN laundry l ON gl.l_no = l.l_no
    WHERE gl.s_id = p_student_id
      AND MONTH(gl.submission_date) = p_month
      AND YEAR(gl.submission_date) = p_year;

    SET total = mess_fee + laundry_charges;

    -- total paid in that month (fees.p_date in month/year joined via student_room_fees)
    SELECT IFNULL(SUM(f.amount),0) INTO total_paid
    FROM student_room_fees srf
    JOIN fees f ON srf.p_id = f.p_id
    WHERE srf.s_id = p_student_id
      AND MONTH(f.p_date) = p_month
      AND YEAR(f.p_date) = p_year;

    SELECT mess_fee AS mess_fee, laundry_charges AS laundry_charges, total AS total_charges,
           total_paid AS total_paid, (total - total_paid) AS balance;
END$$

-- 6) Get all occupants in a room
CREATE PROCEDURE sp_get_room_occupants(IN p_room_no VARCHAR(10))
BEGIN
    SELECT s.s_id, CONCAT(s.f_name, ' ', IFNULL(s.m_name, ''), ' ', s.l_name) AS name,
           srf.allotment_date, lg.name AS guardian
    FROM student s
    JOIN student_room_fees srf ON s.s_id = srf.s_id
    LEFT JOIN local_guardian lg ON s.s_id = lg.s_id
    WHERE srf.r_no = p_room_no;
END$$

-- 7) Submit laundry (wraps insert into gives_laundry)
CREATE PROCEDURE sp_submit_laundry(
    IN p_student_id VARCHAR(20),
    IN p_laundry_no VARCHAR(20)
)
BEGIN
    INSERT INTO gives_laundry (s_id, l_no, submission_date)
    VALUES (p_student_id, p_laundry_no, CURDATE());
END$$

-- 8) Generate a simple hostel report
CREATE PROCEDURE sp_generate_hostel_report()
BEGIN
    -- Room statistics
    SELECT 'total_rooms' AS metric, COUNT(*) AS value FROM room
    UNION ALL
    SELECT 'total_occupancy', IFNULL(SUM(no_of_people),0) FROM room
    UNION ALL
    SELECT 'total_students', COUNT(*) FROM student
    UNION ALL
    SELECT 'total_revenue', IFNULL(SUM(amount),0) FROM fees;
END$$

DELIMITER ;

-- Ensure current DB selected
USE hostel_management;
