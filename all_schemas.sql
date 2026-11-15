-- =============================================
-- AI Powered Tuition Management System - Full MySQL Schema
-- Includes all updates, fixes, and new tables.
-- Runs without foreign key constraint errors.
-- =============================================

CREATE DATABASE IF NOT EXISTS tuition_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tuition_system;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. USERS (Auth table)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin','teacher','student') NOT NULL DEFAULT 'student',
    avatar VARCHAR(255) DEFAULT NULL,
    status ENUM('active','inactive','pending') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 2. SUBJECTS
CREATE TABLE IF NOT EXISTS subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. STUDENTS
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    roll_number VARCHAR(50) UNIQUE,
    date_of_birth DATE,
    gender ENUM('male','female','other'),
    phone VARCHAR(20),
    address TEXT,
    parent_name VARCHAR(150),
    parent_phone VARCHAR(20),
    grade VARCHAR(20),
    admission_date DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 4. TEACHERS
CREATE TABLE IF NOT EXISTS teachers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    qualification VARCHAR(255),
    specialization VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    gender ENUM('male','female','other'),
    experience_years INT DEFAULT 0,
    salary DECIMAL(10,2) DEFAULT 0.00,
    document_path VARCHAR(255),
    approval_status ENUM('pending','approved','rejected') DEFAULT 'pending',
    joined_date DATE DEFAULT (CURRENT_DATE),
    rating DECIMAL(3,2) DEFAULT 0.00,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 5. BATCHES
CREATE TABLE IF NOT EXISTS batches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    teacher_id INT,
    subject_id INT,
    grade VARCHAR(20),
    schedule TEXT,
    max_students INT DEFAULT 30,
    status ENUM('active','inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
);

-- 6. BATCH STUDENTS (enrollment)
CREATE TABLE IF NOT EXISTS batch_students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    student_id INT NOT NULL,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- 7. SCHEDULES (Missing table added)
CREATE TABLE IF NOT EXISTS schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    day_of_week ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
    start_time TIME,
    end_time TIME,
    location VARCHAR(200) DEFAULT 'Online',
    title VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE
);

-- 8. ATTENDANCE (Student)
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    batch_id INT,
    date DATE NOT NULL,
    status ENUM('present','absent','late') DEFAULT 'present',
    marked_by INT,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE,
    FOREIGN KEY (marked_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 9. TEACHER ATTENDANCE (New)
CREATE TABLE IF NOT EXISTS teacher_attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    date DATE NOT NULL,
    status ENUM('present','absent','late') DEFAULT 'present',
    marked_by INT,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_teacher_date (teacher_id, date),
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (marked_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 10. EXAMS
CREATE TABLE IF NOT EXISTS exams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    subject_id INT,
    batch_id INT,
    exam_date DATE,
    total_marks INT DEFAULT 100,
    pass_marks INT DEFAULT 40,
    exam_type ENUM('unit_test','mid_term','final','practice') DEFAULT 'unit_test',
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 11. RESULTS
CREATE TABLE IF NOT EXISTS results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    marks_obtained DECIMAL(5,2) DEFAULT 0,
    grade_letter VARCHAR(5),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);

-- 12. ASSIGNMENTS
CREATE TABLE IF NOT EXISTS assignments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    subject_id INT,
    batch_id INT,
    due_date DATETIME,
    file_path VARCHAR(255),
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 13. SUBMISSIONS
CREATE TABLE IF NOT EXISTS submissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    assignment_id INT NOT NULL,
    student_id INT NOT NULL,
    file_path VARCHAR(255),
    remarks TEXT,
    marks DECIMAL(5,2),
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('submitted','graded','late') DEFAULT 'submitted',
    FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- 14. FEES
CREATE TABLE IF NOT EXISTS fees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description VARCHAR(255),
    due_date DATE,
    paid_date DATE,
    status ENUM('paid','unpaid','partial','overdue') DEFAULT 'unpaid',
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- 15. SALARY
CREATE TABLE IF NOT EXISTS salary (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    month VARCHAR(20),
    year INT,
    paid_date DATE,
    status ENUM('paid','pending') DEFAULT 'pending',
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- 16. SALARY REQUESTS (New)
CREATE TABLE IF NOT EXISTS salary_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reason TEXT,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    admin_remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- 17. MESSAGES
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    message TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 18. NOTIFICATIONS
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200),
    message TEXT,
    type VARCHAR(50) DEFAULT 'info',
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 19. COMPLAINTS
CREATE TABLE IF NOT EXISTS complaints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    against_user_id INT,
    subject VARCHAR(200),
    description TEXT,
    status ENUM('open','in_review','resolved','closed') DEFAULT 'open',
    admin_response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (against_user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 20. FEEDBACK
CREATE TABLE IF NOT EXISTS feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    target_user_id INT,
    target_type ENUM('teacher','course','platform') DEFAULT 'platform',
    rating INT DEFAULT 5,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (target_user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 21. HELPDESK TICKETS (Missing table added)
CREATE TABLE IF NOT EXISTS helpdesk_tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subject VARCHAR(200),
    message TEXT,
    priority ENUM('low','medium','high') DEFAULT 'medium',
    status ENUM('open','in_progress','resolved','closed') DEFAULT 'open',
    admin_response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 22. STUDY MATERIALS
CREATE TABLE IF NOT EXISTS study_materials (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    file_path VARCHAR(255),
    subject_id INT,
    uploaded_by INT,
    type ENUM('pdf','video','image','link') DEFAULT 'pdf',
    download_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
    FOREIGN KEY (uploaded_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 23. AI PREDICTIONS
CREATE TABLE IF NOT EXISTS ai_predictions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    prediction_type VARCHAR(100),
    predicted_value TEXT,
    confidence_score DECIMAL(5,2),
    factors TEXT,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- 24. PACKAGES
CREATE TABLE IF NOT EXISTS packages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    duration_months INT,
    type ENUM('all_subjects','specific_subject','extracurricular') DEFAULT 'all_subjects',
    teacher_id INT,
    subject_ids TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL
);

-- 25. TRANSACTIONS
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    type ENUM('fee_payment','salary','refund','other') DEFAULT 'fee_payment',
    description VARCHAR(255),
    reference_id INT,
    status ENUM('success','pending','failed') DEFAULT 'success',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 26. NOTICE BOARD
CREATE TABLE IF NOT EXISTS notices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    target_role ENUM('all','student','teacher','admin') DEFAULT 'all',
    created_by INT,
    is_pinned TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 27. DOUBTS (Fixed with teacher_id)
CREATE TABLE IF NOT EXISTS doubts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    subject_id INT,
    teacher_id INT,
    title VARCHAR(200),
    description TEXT,
    status ENUM('open','answered','closed') DEFAULT 'open',
    answered_by INT,
    answer TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL,
    FOREIGN KEY (answered_by) REFERENCES users(id) ON DELETE SET NULL
);

-- 28. LIVE CLASSES
CREATE TABLE IF NOT EXISTS live_classes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200),
    batch_id INT,
    teacher_id INT,
    room_id VARCHAR(100) UNIQUE,
    scheduled_at DATETIME,
    duration_minutes INT DEFAULT 60,
    status ENUM('scheduled','live','ended') DEFAULT 'scheduled',
    recording_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE SET NULL,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL
);

-- 29. ADMISSION REQUESTS
CREATE TABLE IF NOT EXISTS admission_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    batch_id INT NOT NULL,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    admin_remarks TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE
);

-- 30. FORUM POSTS (Missing table added)
CREATE TABLE IF NOT EXISTS forum_posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200),
    content TEXT,
    category VARCHAR(50) DEFAULT 'General',
    is_pinned TINYINT(1) DEFAULT 0,
    replies_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 31. FORUM REPLIES (Missing table added)
CREATE TABLE IF NOT EXISTS forum_replies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES forum_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================
-- SEED DATA
-- =============================================
-- Admin user (password: admin123)
INSERT IGNORE INTO users (id, name, email, password, role, status) VALUES 
(1, 'System Admin', 'admin@edusys.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'active'),
(2, 'Demo Teacher', 'teacher@edusys.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'teacher', 'active'),
(3, 'Demo Student', 'student@edusys.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'student', 'active');

INSERT IGNORE INTO subjects (id, name, code, description) VALUES
(1, 'Mathematics', 'MATH101', 'Advanced Mathematics including Calculus and Algebra'),
(2, 'Physics', 'PHY101', 'Classical and Modern Physics'),
(3, 'Chemistry', 'CHEM101', 'Organic and Inorganic Chemistry'),
(4, 'English', 'ENG101', 'English Grammar and Literature'),
(5, 'Computer Science', 'CS101', 'Programming and Computer Fundamentals'),
(6, 'Biology', 'BIO101', 'Human Biology and Life Sciences'),
(7, 'History', 'HIST101', 'World History'),
(8, 'Economics', 'ECO101', 'Micro and Macroeconomics');

-- Teacher profile
INSERT IGNORE INTO teachers (id, user_id, qualification, specialization, phone, experience_years, salary, approval_status) VALUES
(1, 2, 'M.Sc Mathematics', 'Mathematics, Physics', '9876543210', 5, 35000.00, 'approved');

-- Student profile
INSERT IGNORE INTO students (id, user_id, roll_number, gender, phone, grade, parent_name) VALUES
(1, 3, 'STU001', 'male', '9876543211', 'Grade 10', 'Parent Name');

-- Batch
INSERT IGNORE INTO batches (id, name, teacher_id, subject_id, grade, schedule, max_students) VALUES
(1, 'Math Batch A', 1, 1, 'Grade 10', 'Mon/Wed/Fri 4PM-5PM', 25),
(2, 'Physics Batch B', 1, 2, 'Grade 11', 'Tue/Thu 3PM-4PM', 20);

-- Enroll demo student in batch for testing
INSERT IGNORE INTO batch_students (batch_id, student_id) VALUES (1, 1);

-- Sample schedule
INSERT IGNORE INTO schedules (batch_id, day_of_week, start_time, end_time, location, title) VALUES
(1, 'Monday', '16:00:00', '17:00:00', 'Room A', 'Mathematics Class'),
(1, 'Wednesday', '16:00:00', '17:00:00', 'Room A', 'Mathematics Class'),
(1, 'Friday', '16:00:00', '17:00:00', 'Room A', 'Mathematics Class'),
(2, 'Tuesday', '15:00:00', '16:00:00', 'Room B', 'Physics Class'),
(2, 'Thursday', '15:00:00', '16:00:00', 'Room B', 'Physics Class');

-- Notices
INSERT IGNORE INTO notices (title, content, target_role, created_by, is_pinned) VALUES
('Welcome to EduSys!', 'Welcome to our AI-powered tuition management system. Explore all features available to you.', 'all', 1, 1),
('Fee Payment Reminder', 'Please ensure all fees are paid by the end of this month.', 'student', 1, 0),
('New Batch Starting', 'A new Science batch is starting next Monday. Limited seats available!', 'all', 1, 0);

-- Sample helpdesk tickets
INSERT IGNORE INTO helpdesk_tickets (user_id, subject, message, priority, status) VALUES
(3, 'Cannot access study materials', 'I am unable to download study materials from the materials page.', 'medium', 'open'),
(2, 'Salary payment issue', 'My salary for March has not been credited yet. Please look into this.', 'high', 'open');
SET FOREIGN_KEY_CHECKS = 0;
USE tuition_system;

CREATE TABLE IF NOT EXISTS test_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL,
    question TEXT NOT NULL,
    option_a VARCHAR(300),
    option_b VARCHAR(300),
    option_c VARCHAR(300),
    option_d VARCHAR(300),
    correct_answer ENUM('a','b','c','d'),
    marks INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS test_attempts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    answers TEXT,
    score DECIMAL(5,2) DEFAULT 0,
    total_questions INT DEFAULT 0,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bookmarks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    material_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS payout_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    bank_details TEXT,
    status ENUM('pending','approved','paid','rejected') DEFAULT 'pending',
    admin_note TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add missing columns if not present
ALTER TABLE users MODIFY COLUMN avatar VARCHAR(255) DEFAULT NULL;
ALTER TABLE teachers MODIFY COLUMN phone VARCHAR(20) DEFAULT NULL;
ALTER TABLE teachers MODIFY COLUMN address TEXT DEFAULT NULL;
ALTER TABLE teachers MODIFY COLUMN gender VARCHAR(10) DEFAULT NULL;

SET FOREIGN_KEY_CHECKS = 1;
-- =============================================
-- EduSys – Final Database Patch
-- Run this AFTER database.sql to add missing tables & columns
-- Compatible with XAMPP and InfinityFree
-- =============================================

USE tuition_system;

-- =============================================
-- FIX: helpdesk_tickets (referenced in helpdesk.php but MISSING from original schema)
-- =============================================
CREATE TABLE IF NOT EXISTS helpdesk_tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subject VARCHAR(200),
    message TEXT,
    priority ENUM('low','medium','high') DEFAULT 'medium',
    status ENUM('open','in_progress','resolved','closed') DEFAULT 'open',
    admin_response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =============================================
-- FIX: forum_posts (referenced in student/forum.php but MISSING from original schema)
-- =============================================
CREATE TABLE IF NOT EXISTS forum_posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200),
    content TEXT,
    category VARCHAR(50) DEFAULT 'General',
    is_pinned TINYINT(1) DEFAULT 0,
    replies_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =============================================
-- FIX: forum_replies (referenced in student/forum.php but MISSING from original schema)
-- =============================================
CREATE TABLE IF NOT EXISTS forum_replies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES forum_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =============================================
-- FIX: schedules (referenced in student/schedule.php but MISSING from original schema)
-- =============================================
CREATE TABLE IF NOT EXISTS schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    day_of_week ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
    start_time TIME,
    end_time TIME,
    location VARCHAR(200) DEFAULT 'Online',
    title VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE
);

-- =============================================
-- NEW: teacher_attendance (admin teacher attendance management)
-- =============================================
CREATE TABLE IF NOT EXISTS teacher_attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    date DATE NOT NULL,
    status ENUM('present','absent','late') DEFAULT 'present',
    marked_by INT,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_teacher_date (teacher_id, date),
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (marked_by) REFERENCES users(id) ON DELETE SET NULL
);

-- =============================================
-- NEW: salary_requests (teachers submit salary requests)
-- =============================================
CREATE TABLE IF NOT EXISTS salary_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reason TEXT,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    admin_remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- =============================================
-- FIX: doubts – add teacher_id column for teacher selection
-- =============================================
ALTER TABLE doubts
    ADD COLUMN IF NOT EXISTS teacher_id INT AFTER subject_id,
    ADD CONSTRAINT FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL;

-- Some MySQL versions don't support IF NOT EXISTS for ALTER, so use this fallback:
-- (The above will be fine on MySQL 8.0.3+; for older versions a procedure is safer)

-- =============================================
-- FIX: feedback – ensure teacher_id and batch_id columns exist
-- =============================================
-- feedback table already exists in original schema, just verify structure

-- =============================================
-- FIX: notifications table safety (already in schema, ensure exists)
-- =============================================
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200),
    message TEXT,
    type VARCHAR(50) DEFAULT 'info',
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =============================================
-- SEED: Sample helpdesk tickets for testing
-- =============================================
INSERT IGNORE INTO helpdesk_tickets (user_id, subject, message, priority, status) VALUES
(3, 'Cannot access study materials', 'I am unable to download study materials from the materials page.', 'medium', 'open'),
(2, 'Salary payment issue', 'My salary for March has not been credited yet. Please look into this.', 'high', 'open');

-- =============================================
-- SEED: Sample schedule for testing
-- =============================================
INSERT IGNORE INTO schedules (batch_id, day_of_week, start_time, end_time, location, title) VALUES
(1, 'Monday', '16:00:00', '17:00:00', 'Room A', 'Mathematics Class'),
(1, 'Wednesday', '16:00:00', '17:00:00', 'Room A', 'Mathematics Class'),
(1, 'Friday', '16:00:00', '17:00:00', 'Room A', 'Mathematics Class'),
(2, 'Tuesday', '15:00:00', '16:00:00', 'Room B', 'Physics Class'),
(2, 'Thursday', '15:00:00', '16:00:00', 'Room B', 'Physics Class');

-- =============================================
-- SEED: Enroll demo student in batch for testing
-- =============================================
INSERT IGNORE INTO batch_students (batch_id, student_id) VALUES (1, 1);
-- =============================================
-- EduSys Additional Tables (run after database.sql)
-- =============================================
USE tuition_system;

-- HELP DESK TICKETS
CREATE TABLE IF NOT EXISTS helpdesk_tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subject VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    status ENUM('open','in_progress','resolved','closed') DEFAULT 'open',
    admin_response TEXT,
    priority ENUM('low','medium','high') DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- FORUM POSTS
CREATE TABLE IF NOT EXISTS forum_posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(100) DEFAULT 'General',
    likes INT DEFAULT 0,
    replies_count INT DEFAULT 0,
    is_pinned TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- FORUM REPLIES
CREATE TABLE IF NOT EXISTS forum_replies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES forum_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- SCHEDULES
CREATE TABLE IF NOT EXISTS schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    batch_id INT,
    title VARCHAR(200),
    day_of_week ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
    start_time TIME,
    end_time TIME,
    location VARCHAR(200) DEFAULT 'Online',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE SET NULL
);

-- TEST/QUIZ QUESTIONS
CREATE TABLE IF NOT EXISTS test_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL,
    question TEXT NOT NULL,
    option_a VARCHAR(300),
    option_b VARCHAR(300),
    option_c VARCHAR(300),
    option_d VARCHAR(300),
    correct_answer ENUM('a','b','c','d'),
    marks INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);

-- TEST ATTEMPTS (student responses)
CREATE TABLE IF NOT EXISTS test_attempts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    answers TEXT,
    score DECIMAL(5,2) DEFAULT 0,
    total_questions INT DEFAULT 0,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);

-- BOOKMARKS
CREATE TABLE IF NOT EXISTS bookmarks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    material_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (material_id) REFERENCES study_materials(id) ON DELETE CASCADE
);

-- PAYOUT REQUESTS
CREATE TABLE IF NOT EXISTS payout_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    bank_details TEXT,
    status ENUM('pending','approved','paid','rejected') DEFAULT 'pending',
    admin_note TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- Add avatar columns if not present
ALTER TABLE users MODIFY COLUMN avatar VARCHAR(255) DEFAULT NULL;

-- Sample helpdesk ticket
INSERT IGNORE INTO helpdesk_tickets (user_id, subject, message, status) VALUES
(3, 'Cannot access study materials', 'I am unable to download the study materials for Mathematics. Please help.', 'open'),
(2, 'Salary not yet credited', 'My salary for March 2026 has not been credited to my account.', 'open');

-- Sample forum posts
INSERT IGNORE INTO forum_posts (user_id, title, content, category) VALUES
(3, 'Tips for Calculus?', 'Can anyone share good tips for understanding integration by parts?', 'Academic'),
(2, 'Online class schedule for next week', 'Sharing the updated schedule for Monday Math class.', 'Announcements');
DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS exams;
-- =============================================
-- FIXING DOUBTS TABLE SCHEMA
-- This script adds the missing teacher_id column
-- =============================================

SET FOREIGN_KEY_CHECKS = 0;

-- Check if teacher_id exists, if not add it
ALTER TABLE `doubts` ADD COLUMN IF NOT EXISTS `teacher_id` INT DEFAULT NULL AFTER `subject_id`;

-- Add foreign key constraint to ensure data integrity
-- (If it already exists, this command might fail, which is fine)
ALTER TABLE `doubts` 
ADD CONSTRAINT `doubts_ibfk_teacher` 
FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE SET NULL;

SET FOREIGN_KEY_CHECKS = 1;
-- =============================================
-- EMERGENCY FIX FOR EXAMS & RESULTS TABLES
-- This script uses a DISCARD/IMPORT tablespace bypass
-- and forces the creation of these tables safely.
-- =============================================

SET FOREIGN_KEY_CHECKS = 0;

-- Drop dependent table first
DROP TABLE IF EXISTS `results`;
DROP TABLE IF EXISTS `exams`;

-- Attempt to clear ghost files in some MariaDB versions
-- (If this fails, follow the manual file deletion steps I provided)
FLUSH TABLES;

-- Create EXAMS table
CREATE TABLE `exams` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `exam_date` date DEFAULT NULL,
  `total_marks` int(11) DEFAULT 100,
  `pass_marks` int(11) DEFAULT 40,
  `exam_type` enum('unit_test','mid_term','final','practice') DEFAULT 'unit_test',
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `subject_id` (`subject_id`),
  KEY `batch_id` (`batch_id`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `exams_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `exams_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`) ON DELETE SET NULL,
  CONSTRAINT `exams_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create RESULTS table
CREATE TABLE `results` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `student_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `marks_obtained` decimal(5,2) DEFAULT 0.00,
  `grade_letter` varchar(5) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  KEY `exam_id` (`exam_id`),
  CONSTRAINT `results_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `results_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
-- =============================================
-- FIX: Missing columns in teachers table
-- Run this in your InfinityFree PHPMyAdmin
-- =============================================

USE `epiz_XXXXXXXX_db`; -- Change this to your actual database name

ALTER TABLE teachers 
ADD COLUMN IF NOT EXISTS verification_status ENUM('pending_submission', 'submitted', 'verified', 'rejected') DEFAULT 'pending_submission',
ADD COLUMN IF NOT EXISTS aadhar_number VARCHAR(20) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS aadhar_file VARCHAR(255) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS certificate_file VARCHAR(255) DEFAULT NULL;

-- Also fix results table name if it's missing (used in student portal)
CREATE TABLE IF NOT EXISTS exams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200),
    subject_id INT,
    batch_id INT,
    exam_date DATE,
    total_marks INT DEFAULT 100,
    pass_marks INT DEFAULT 40,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    exam_id INT,
    marks_obtained DECIMAL(5,2),
    grade_letter VARCHAR(5),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE notices ADD COLUMN IF NOT EXISTS batch_id INT DEFAULT NULL AFTER target_role;
ALTER TABLE notices ADD CONSTRAINT fk_notices_batch FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE;

-- WebRTC tables for live class video calling
CREATE TABLE IF NOT EXISTS webrtc_peers (
    class_id INT NOT NULL,
    user_id INT NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    user_role VARCHAR(20) NOT NULL,
    last_ping TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (class_id, user_id)
);

CREATE TABLE IF NOT EXISTS webrtc_signals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    from_user INT NOT NULL,
    to_user INT NOT NULL,
    signal_type VARCHAR(50) NOT NULL,
    signal_data TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_signals_poll (to_user, is_read, class_id)
);

-- Fix messages table: add batch_id for group chat, allow NULL receiver_id
ALTER TABLE messages ADD COLUMN batch_id INT DEFAULT NULL AFTER receiver_id;
ALTER TABLE messages MODIFY receiver_id INT DEFAULT NULL;
-- =============================================
-- Live Class System - Database Migration
-- Run this on both XAMPP (local) and InfinityFree (hosting)
-- =============================================

SET FOREIGN_KEY_CHECKS = 0;

-- Ensure live_classes has all needed columns (may already exist, we ALTER safely)
ALTER TABLE live_classes
    ADD COLUMN IF NOT EXISTS `end_time` DATETIME DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `start_time` DATETIME DEFAULT NULL;

-- Live Attendance
CREATE TABLE IF NOT EXISTS live_attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    student_id INT NOT NULL,
    join_time DATETIME DEFAULT NULL,
    leave_time DATETIME DEFAULT NULL,
    duration INT DEFAULT 0 COMMENT 'in seconds',
    percentage DECIMAL(5,2) DEFAULT 0.00,
    UNIQUE KEY unique_attendance (class_id, student_id),
    FOREIGN KEY (class_id) REFERENCES live_classes(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Live Chat Messages
CREATE TABLE IF NOT EXISTS live_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES live_classes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Recordings
CREATE TABLE IF NOT EXISTS recordings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES live_classes(id) ON DELETE CASCADE
);

-- Live Class Doubts (post-class)
CREATE TABLE IF NOT EXISTS live_doubts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    student_id INT NOT NULL,
    question TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES live_classes(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Live Doubt Replies
CREATE TABLE IF NOT EXISTS live_doubt_replies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doubt_id INT NOT NULL,
    user_id INT NOT NULL,
    reply TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (doubt_id) REFERENCES live_doubts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

SET FOREIGN_KEY_CHECKS = 1;
-- =============================================
-- EduSys Additional Tables (run after database.sql)
-- =============================================
USE tuition_system;

-- HELP DESK TICKETS
CREATE TABLE IF NOT EXISTS helpdesk_tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subject VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    status ENUM('open','in_progress','resolved','closed') DEFAULT 'open',
    admin_response TEXT,
    priority ENUM('low','medium','high') DEFAULT 'medium',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- FORUM POSTS
CREATE TABLE IF NOT EXISTS forum_posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(100) DEFAULT 'General',
    likes INT DEFAULT 0,
    replies_count INT DEFAULT 0,
    is_pinned TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- FORUM REPLIES
CREATE TABLE IF NOT EXISTS forum_replies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES forum_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- SCHEDULES
CREATE TABLE IF NOT EXISTS schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    batch_id INT,
    title VARCHAR(200),
    day_of_week ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
    start_time TIME,
    end_time TIME,
    location VARCHAR(200) DEFAULT 'Online',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE SET NULL
);

-- TEST/QUIZ QUESTIONS
CREATE TABLE IF NOT EXISTS test_questions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exam_id INT NOT NULL,
    question TEXT NOT NULL,
    option_a VARCHAR(300),
    option_b VARCHAR(300),
    option_c VARCHAR(300),
    option_d VARCHAR(300),
    correct_answer ENUM('a','b','c','d'),
    marks INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);

-- TEST ATTEMPTS (student responses)
CREATE TABLE IF NOT EXISTS test_attempts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    answers TEXT,
    score DECIMAL(5,2) DEFAULT 0,
    total_questions INT DEFAULT 0,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);

-- BOOKMARKS
CREATE TABLE IF NOT EXISTS bookmarks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    material_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (material_id) REFERENCES study_materials(id) ON DELETE CASCADE
);

-- PAYOUT REQUESTS
CREATE TABLE IF NOT EXISTS payout_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    bank_details TEXT,
    status ENUM('pending','approved','paid','rejected') DEFAULT 'pending',
    admin_note TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- Add avatar columns if not present
ALTER TABLE users MODIFY COLUMN avatar VARCHAR(255) DEFAULT NULL;

-- Sample helpdesk ticket
INSERT IGNORE INTO helpdesk_tickets (user_id, subject, message, status) VALUES
(3, 'Cannot access study materials', 'I am unable to download the study materials for Mathematics. Please help.', 'open'),
(2, 'Salary not yet credited', 'My salary for March 2026 has not been credited to my account.', 'open');

-- Sample forum posts
INSERT IGNORE INTO forum_posts (user_id, title, content, category) VALUES
(3, 'Tips for Calculus?', 'Can anyone share good tips for understanding integration by parts?', 'Academic'),
(2, 'Online class schedule for next week', 'Sharing the updated schedule for Monday Math class.', 'Announcements');
-- =============================================
-- EduSys – Final Database Patch
-- Run this AFTER database.sql to add missing tables & columns
-- Compatible with XAMPP and InfinityFree
-- =============================================

USE tuition_system;

-- =============================================
-- FIX: helpdesk_tickets (referenced in helpdesk.php but MISSING from original schema)
-- =============================================
CREATE TABLE IF NOT EXISTS helpdesk_tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    subject VARCHAR(200),
    message TEXT,
    priority ENUM('low','medium','high') DEFAULT 'medium',
    status ENUM('open','in_progress','resolved','closed') DEFAULT 'open',
    admin_response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =============================================
-- FIX: forum_posts (referenced in student/forum.php but MISSING from original schema)
-- =============================================
CREATE TABLE IF NOT EXISTS forum_posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200),
    content TEXT,
    category VARCHAR(50) DEFAULT 'General',
    is_pinned TINYINT(1) DEFAULT 0,
    replies_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =============================================
-- FIX: forum_replies (referenced in student/forum.php but MISSING from original schema)
-- =============================================
CREATE TABLE IF NOT EXISTS forum_replies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES forum_posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =============================================
-- FIX: schedules (referenced in student/schedule.php but MISSING from original schema)
-- =============================================
CREATE TABLE IF NOT EXISTS schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    day_of_week ENUM('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
    start_time TIME,
    end_time TIME,
    location VARCHAR(200) DEFAULT 'Online',
    title VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE
);

-- =============================================
-- NEW: teacher_attendance (admin teacher attendance management)
-- =============================================
CREATE TABLE IF NOT EXISTS teacher_attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    date DATE NOT NULL,
    status ENUM('present','absent','late') DEFAULT 'present',
    marked_by INT,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_teacher_date (teacher_id, date),
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (marked_by) REFERENCES users(id) ON DELETE SET NULL
);

-- =============================================
-- NEW: salary_requests (teachers submit salary requests)
-- =============================================
CREATE TABLE IF NOT EXISTS salary_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reason TEXT,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    admin_remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

-- =============================================
-- FIX: doubts – add teacher_id column for teacher selection
-- =============================================
ALTER TABLE doubts
    ADD COLUMN IF NOT EXISTS teacher_id INT AFTER subject_id,
    ADD CONSTRAINT FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL;

-- Some MySQL versions don't support IF NOT EXISTS for ALTER, so use this fallback:
-- (The above will be fine on MySQL 8.0.3+; for older versions a procedure is safer)

-- =============================================
-- FIX: feedback – ensure teacher_id and batch_id columns exist
-- =============================================
-- feedback table already exists in original schema, just verify structure

-- =============================================
-- FIX: notifications table safety (already in schema, ensure exists)
-- =============================================
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200),
    message TEXT,
    type VARCHAR(50) DEFAULT 'info',
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =============================================
-- SEED: Sample helpdesk tickets for testing
-- =============================================
INSERT IGNORE INTO helpdesk_tickets (user_id, subject, message, priority, status) VALUES
(3, 'Cannot access study materials', 'I am unable to download study materials from the materials page.', 'medium', 'open'),
(2, 'Salary payment issue', 'My salary for March has not been credited yet. Please look into this.', 'high', 'open');

-- =============================================
-- SEED: Sample schedule for testing
-- =============================================
INSERT IGNORE INTO schedules (batch_id, day_of_week, start_time, end_time, location, title) VALUES
(1, 'Monday', '16:00:00', '17:00:00', 'Room A', 'Mathematics Class'),
(1, 'Wednesday', '16:00:00', '17:00:00', 'Room A', 'Mathematics Class'),
(1, 'Friday', '16:00:00', '17:00:00', 'Room A', 'Mathematics Class'),
(2, 'Tuesday', '15:00:00', '16:00:00', 'Room B', 'Physics Class'),
(2, 'Thursday', '15:00:00', '16:00:00', 'Room B', 'Physics Class');

-- =============================================
-- SEED: Enroll demo student in batch for testing
-- =============================================
INSERT IGNORE INTO batch_students (batch_id, student_id) VALUES (1, 1);
-- =============================================
-- Live Class System - Database Migration
-- Run this on both XAMPP (local) and InfinityFree (hosting)
-- =============================================

SET FOREIGN_KEY_CHECKS = 0;

-- Ensure live_classes has all needed columns (may already exist, we ALTER safely)
ALTER TABLE live_classes
    ADD COLUMN IF NOT EXISTS `end_time` DATETIME DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `start_time` DATETIME DEFAULT NULL;

-- Live Attendance
CREATE TABLE IF NOT EXISTS live_attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    student_id INT NOT NULL,
    join_time DATETIME DEFAULT NULL,
    leave_time DATETIME DEFAULT NULL,
    duration INT DEFAULT 0 COMMENT 'in seconds',
    percentage DECIMAL(5,2) DEFAULT 0.00,
    UNIQUE KEY unique_attendance (class_id, student_id),
    FOREIGN KEY (class_id) REFERENCES live_classes(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Live Chat Messages
CREATE TABLE IF NOT EXISTS live_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    user_id INT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES live_classes(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Recordings
CREATE TABLE IF NOT EXISTS recordings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES live_classes(id) ON DELETE CASCADE
);

-- Live Class Doubts (post-class)
CREATE TABLE IF NOT EXISTS live_doubts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    student_id INT NOT NULL,
    question TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (class_id) REFERENCES live_classes(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- Live Doubt Replies
CREATE TABLE IF NOT EXISTS live_doubt_replies (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doubt_id INT NOT NULL,
    user_id INT NOT NULL,
    reply TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (doubt_id) REFERENCES live_doubts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

SET FOREIGN_KEY_CHECKS = 1;
-- =============================================
-- Parent Panel — Database Migration
-- Run this on tuition_system database
-- =============================================
USE tuition_system;

-- 1. Add 'parent' role to users ENUM
ALTER TABLE users MODIFY COLUMN role ENUM('admin','teacher','student','parent') NOT NULL DEFAULT 'student';

-- 2. Parent-Student link table (supports multi-child)
CREATE TABLE IF NOT EXISTS parent_students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NOT NULL,
    student_id INT NOT NULL,
    relationship ENUM('father','mother','guardian','other') DEFAULT 'guardian',
    is_primary TINYINT(1) DEFAULT 1,
    linked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_parent_student (parent_id, student_id),
    FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- 3. Parent-Teacher meeting requests
CREATE TABLE IF NOT EXISTS ptm_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NOT NULL,
    teacher_id INT NOT NULL,
    student_id INT NOT NULL,
    requested_date DATE,
    requested_time TIME,
    reason TEXT,
    status ENUM('pending','approved','rejected','completed') DEFAULT 'pending',
    teacher_remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- 4. Update notices table to support parent role
ALTER TABLE notices MODIFY COLUMN target_role ENUM('all','student','teacher','admin','parent') DEFAULT 'all';

-- 5. Seed a demo parent user (password: password)
INSERT IGNORE INTO users (id, name, email, password, role, status) VALUES
(4, 'Demo Parent', 'parent@edusys.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'parent', 'active');

-- 6. Link demo parent to demo student (student_id=1)
INSERT IGNORE INTO parent_students (parent_id, student_id, relationship) VALUES (4, 1, 'father');
-- =============================================
-- EMERGENCY FIX FOR EXAMS & RESULTS TABLES
-- This script uses a DISCARD/IMPORT tablespace bypass
-- and forces the creation of these tables safely.
-- =============================================

SET FOREIGN_KEY_CHECKS = 0;

-- Drop dependent table first
DROP TABLE IF EXISTS `results`;
DROP TABLE IF EXISTS `exams`;

-- Attempt to clear ghost files in some MariaDB versions
-- (If this fails, follow the manual file deletion steps I provided)
FLUSH TABLES;

-- Create EXAMS table
CREATE TABLE `exams` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `exam_date` date DEFAULT NULL,
  `total_marks` int(11) DEFAULT 100,
  `pass_marks` int(11) DEFAULT 40,
  `exam_type` enum('unit_test','mid_term','final','practice') DEFAULT 'unit_test',
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `subject_id` (`subject_id`),
  KEY `batch_id` (`batch_id`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `exams_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`) ON DELETE SET NULL,
  CONSTRAINT `exams_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`) ON DELETE SET NULL,
  CONSTRAINT `exams_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create RESULTS table
CREATE TABLE `results` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `student_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `marks_obtained` decimal(5,2) DEFAULT 0.00,
  `grade_letter` varchar(5) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `student_id` (`student_id`),
  KEY `exam_id` (`exam_id`),
  CONSTRAINT `results_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  CONSTRAINT `results_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
CREATE TABLE IF NOT EXISTS `examinations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `exam_date` date DEFAULT NULL,
  `total_marks` int(11) DEFAULT 100,
  `pass_marks` int(11) DEFAULT 40,
  `exam_type` varchar(50) DEFAULT 'unit_test',
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `examination_results` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `student_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `marks_obtained` decimal(5,2) DEFAULT NULL,
  `grade_letter` varchar(5) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- =============================================
-- FIX: Missing columns in teachers table
-- Run this in your InfinityFree PHPMyAdmin
-- =============================================

USE `epiz_XXXXXXXX_db`; -- Change this to your actual database name

ALTER TABLE teachers 
ADD COLUMN IF NOT EXISTS verification_status ENUM('pending_submission', 'submitted', 'verified', 'rejected') DEFAULT 'pending_submission',
ADD COLUMN IF NOT EXISTS aadhar_number VARCHAR(20) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS aadhar_file VARCHAR(255) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS certificate_file VARCHAR(255) DEFAULT NULL;

-- Also fix results table name if it's missing (used in student portal)
CREATE TABLE IF NOT EXISTS exams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200),
    subject_id INT,
    batch_id INT,
    exam_date DATE,
    total_marks INT DEFAULT 100,
    pass_marks INT DEFAULT 40,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    exam_id INT,
    marks_obtained DECIMAL(5,2),
    grade_letter VARCHAR(5),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE notices ADD COLUMN IF NOT EXISTS batch_id INT DEFAULT NULL AFTER target_role;
ALTER TABLE notices ADD CONSTRAINT fk_notices_batch FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE;

-- WebRTC tables for live class video calling
CREATE TABLE IF NOT EXISTS webrtc_peers (
    class_id INT NOT NULL,
    user_id INT NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    user_role VARCHAR(20) NOT NULL,
    last_ping TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (class_id, user_id)
);

CREATE TABLE IF NOT EXISTS webrtc_signals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    from_user INT NOT NULL,
    to_user INT NOT NULL,
    signal_type VARCHAR(50) NOT NULL,
    signal_data TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_signals_poll (to_user, is_read, class_id)
);

-- Fix messages table: add batch_id for group chat, allow NULL receiver_id
ALTER TABLE messages ADD COLUMN batch_id INT DEFAULT NULL AFTER receiver_id;
ALTER TABLE messages MODIFY receiver_id INT DEFAULT NULL;
-- =============================================
-- Parent Panel — Database Migration
-- Run this on tuition_system database
-- =============================================
USE tuition_system;

-- 1. Add 'parent' role to users ENUM
ALTER TABLE users MODIFY COLUMN role ENUM('admin','teacher','student','parent') NOT NULL DEFAULT 'student';

-- 2. Parent-Student link table (supports multi-child)
CREATE TABLE IF NOT EXISTS parent_students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NOT NULL,
    student_id INT NOT NULL,
    relationship ENUM('father','mother','guardian','other') DEFAULT 'guardian',
    is_primary TINYINT(1) DEFAULT 1,
    linked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_parent_student (parent_id, student_id),
    FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- 3. Parent-Teacher meeting requests
CREATE TABLE IF NOT EXISTS ptm_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    parent_id INT NOT NULL,
    teacher_id INT NOT NULL,
    student_id INT NOT NULL,
    requested_date DATE,
    requested_time TIME,
    reason TEXT,
    status ENUM('pending','approved','rejected','completed') DEFAULT 'pending',
    teacher_remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- 4. Update notices table to support parent role
ALTER TABLE notices MODIFY COLUMN target_role ENUM('all','student','teacher','admin','parent') DEFAULT 'all';

-- 5. Seed a demo parent user (password: password)
INSERT IGNORE INTO users (id, name, email, password, role, status) VALUES
(4, 'Demo Parent', 'parent@edusys.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'parent', 'active');

-- 6. Link demo parent to demo student (student_id=1)
INSERT IGNORE INTO parent_students (parent_id, student_id, relationship) VALUES (4, 1, 'father');
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin','teacher','student') NOT NULL DEFAULT 'student',
    avatar VARCHAR(255),
    status ENUM('active','inactive','pending') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS subjects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    roll_number VARCHAR(50) UNIQUE,
    date_of_birth DATE,
    gender ENUM('male','female','other'),
    phone VARCHAR(20),
    address TEXT,
    parent_name VARCHAR(150),
    parent_phone VARCHAR(20),
    grade VARCHAR(20),
    admission_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS teachers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    qualification VARCHAR(255),
    specialization VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    gender ENUM('male','female','other'),
    experience_years INT DEFAULT 0,
    salary DECIMAL(10,2) DEFAULT 0,
    document_path VARCHAR(255),
    approval_status ENUM('pending','approved','rejected') DEFAULT 'approved',
    verification_status ENUM('pending_submission','submitted','verified','rejected') DEFAULT 'pending_submission',
    aadhar_number VARCHAR(20),
    aadhar_file VARCHAR(255),
    certificate_file VARCHAR(255),
    joined_date DATE,
    rating DECIMAL(3,2) DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS batches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    teacher_id INT,
    subject_id INT,
    grade VARCHAR(20),
    schedule TEXT,
    max_students INT DEFAULT 30,
    status ENUM('active','inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id),
    FOREIGN KEY (subject_id) REFERENCES subjects(id)
);

CREATE TABLE IF NOT EXISTS batch_students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    batch_id INT NOT NULL,
    student_id INT NOT NULL,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    batch_id INT,
    date DATE NOT NULL,
    status ENUM('present','absent','late') DEFAULT 'present',
    marked_by INT,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS exams (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    subject_id INT,
    batch_id INT,
    exam_date DATE,
    total_marks INT DEFAULT 100,
    pass_marks INT DEFAULT 40,
    exam_type ENUM('unit_test','mid_term','final','practice') DEFAULT 'unit_test',
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS results (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    exam_id INT NOT NULL,
    marks_obtained DECIMAL(5,2) DEFAULT 0,
    grade_letter VARCHAR(5),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS assignments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    subject_id INT,
    batch_id INT,
    due_date DATETIME,
    file_path VARCHAR(255),
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS submissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    assignment_id INT NOT NULL,
    student_id INT NOT NULL,
    file_path VARCHAR(255),
    remarks TEXT,
    marks DECIMAL(5,2),
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('submitted','graded','late') DEFAULT 'submitted',
    FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS fees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    description VARCHAR(255),
    due_date DATE,
    paid_date DATE,
    status ENUM('paid','unpaid','partial','overdue') DEFAULT 'unpaid',
    payment_method VARCHAR(50),
    transaction_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS salary (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    month VARCHAR(20),
    year INT,
    paid_date DATE,
    status ENUM('paid','pending') DEFAULT 'pending',
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT DEFAULT NULL,
    batch_id INT DEFAULT NULL,
    message TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200),
    message TEXT,
    type VARCHAR(50) DEFAULT 'info',
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX(user_id)
) ENGINE=InnoDB;
CREATE TABLE IF NOT EXISTS complaints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    against_user_id INT,
    subject VARCHAR(200),
    description TEXT,
    status ENUM('open','in_review','resolved','closed') DEFAULT 'open',
    admin_response TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS feedback (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    target_user_id INT,
    target_type ENUM('teacher','course','platform') DEFAULT 'platform',
    rating INT DEFAULT 5,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS notices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    target_role ENUM('all','student','teacher','admin') DEFAULT 'all',
    batch_id INT,
    created_by INT,
    is_pinned TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (batch_id) REFERENCES batches(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS study_materials (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    file_path VARCHAR(255),
    subject_id INT,
    uploaded_by INT,
    type ENUM('pdf','video','image','link') DEFAULT 'pdf',
    download_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS doubts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    subject_id INT,
    title VARCHAR(200),
    description TEXT,
    status ENUM('open','answered','closed') DEFAULT 'open',
    answered_by INT,
    answer TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id)
);
CREATE TABLE IF NOT EXISTS live_classes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200),
    batch_id INT,
    teacher_id INT,
    room_id VARCHAR(100) UNIQUE,
    scheduled_at DATETIME,
    duration_minutes INT DEFAULT 60,
    status ENUM('scheduled','live','ended') DEFAULT 'scheduled',
    recording_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS webrtc_peers (
    class_id INT NOT NULL,
    user_id INT NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    user_role VARCHAR(20) NOT NULL,
    last_ping TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (class_id, user_id)
);

CREATE TABLE IF NOT EXISTS webrtc_signals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT NOT NULL,
    from_user INT NOT NULL,
    to_user INT NOT NULL,
    signal_type VARCHAR(50) NOT NULL,
    signal_data TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_signals_poll (to_user, is_read, class_id)
);
CREATE TABLE IF NOT EXISTS packages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    duration_months INT,
    type ENUM('all_subjects','specific_subject','extracurricular') DEFAULT 'all_subjects',
    teacher_id INT,
    subject_ids TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    type ENUM('fee_payment','salary','refund','other') DEFAULT 'fee_payment',
    description VARCHAR(255),
    reference_id INT,
    status ENUM('success','pending','failed') DEFAULT 'success',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS admission_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    batch_id INT NOT NULL,
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    admin_remarks TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS session_bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    teacher_id INT NOT NULL,
    title VARCHAR(255),
    scheduled_at DATETIME,
    duration INT DEFAULT 60,
    status ENUM('pending', 'approved', 'rejected', 'completed') DEFAULT 'pending',
    meeting_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS session_peers (
    session_id INT NOT NULL,
    user_id INT NOT NULL,
    user_name VARCHAR(100) NOT NULL,
    user_role VARCHAR(20) NOT NULL,
    last_ping TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (session_id, user_id)
);

CREATE TABLE IF NOT EXISTS session_signals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    session_id INT NOT NULL,
    from_user INT NOT NULL,
    to_user INT NOT NULL,
    signal_type VARCHAR(50) NOT NULL,
    signal_data TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_signals_poll (session_id, to_user, is_read)
);
CREATE TABLE IF NOT EXISTS teacher_locations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL UNIQUE,
    address TEXT,
    city VARCHAR(100),
    pincode VARCHAR(20),
    latitude DOUBLE,
    longitude DOUBLE,
    is_offline_active TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS offline_batches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    teacher_id INT NOT NULL,
    subject_id INT NOT NULL,
    grade VARCHAR(50),
    timings VARCHAR(200),
    fees DECIMAL(10,2) DEFAULT 0,
    total_seats INT DEFAULT 0,
    available_seats INT DEFAULT 0,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS offline_batch_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    batch_id INT NOT NULL,
    request_note TEXT,
    status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (batch_id) REFERENCES offline_batches(id) ON DELETE CASCADE,
    UNIQUE KEY unique_request (student_id, batch_id)
);
-- Demo Subjects
INSERT IGNORE INTO subjects (name, code) VALUES
('Mathematics','MATH101'),
('Physics','PHY101'),
('Chemistry','CHEM101'),
('English','ENG101'),
('Computer Science','CS101'),
('Biology','BIO101'),
('History','HIST101'),
('Economics','ECO101');

-- Demo Users (password is 'password' hashed)
DELETE FROM users WHERE email IN ('admin@edusys.com','teacher@edusys.com','student@edusys.com');
SET @pass_hash = '$2y$10$34qKnG3WOUWKHdIPr4ejmO18.5o3guvklIp.Fskdd6BW2qEp0zZ6i';

INSERT INTO users (name,email,password,role,status) VALUES ('System Admin','admin@edusys.com',@pass_hash,'admin','active');
INSERT INTO users (name,email,password,role,status) VALUES ('Demo Teacher','teacher@edusys.com',@pass_hash,'teacher','active');
SET @teacher_uid = LAST_INSERT_ID();
INSERT IGNORE INTO teachers (user_id,qualification,specialization,phone,experience_years,salary,approval_status)
VALUES (@teacher_uid,'M.Sc Mathematics','Mathematics, Physics','9876543210',5,35000.00,'approved');

INSERT INTO users (name,email,password,role,status) VALUES ('Demo Student','student@edusys.com',@pass_hash,'student','active');
SET @student_uid = LAST_INSERT_ID();
INSERT IGNORE INTO students (user_id,roll_number,phone,grade,parent_name,admission_date)
VALUES (@student_uid,'STU0001','9876543211','Grade 10','Demo Parent',CURDATE());

-- Demo Notices
SET @admin_uid = (SELECT id FROM users WHERE email='admin@edusys.com');
INSERT IGNORE INTO notices (title,content,target_role,created_by,is_pinned) VALUES
('Welcome to EduSys!','Welcome to the AI-powered tuition system.','all',@admin_uid,1),
('Fee Reminder','Please pay fees before month end.','student',@admin_uid,0);

-- Demo Batch & Enrollment
SET @teacher_tbl_id = (SELECT id FROM teachers WHERE user_id=@teacher_uid);
SET @student_tbl_id = (SELECT id FROM students WHERE user_id=@student_uid);
INSERT IGNORE INTO batches (name,teacher_id,subject_id,grade,status)
VALUES ('Demo Batch - Mathematics',@teacher_tbl_id,1,'Grade 10','active');
SET @demo_batch_id = LAST_INSERT_ID();
INSERT IGNORE INTO batch_students (batch_id,student_id) VALUES (@demo_batch_id,@student_tbl_id);
CREATE TABLE IF NOT EXISTS `examinations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `exam_date` date DEFAULT NULL,
  `total_marks` int(11) DEFAULT 100,
  `pass_marks` int(11) DEFAULT 40,
  `exam_type` varchar(50) DEFAULT 'unit_test',
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `examination_results` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `student_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `marks_obtained` decimal(5,2) DEFAULT NULL,
  `grade_letter` varchar(5) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Chatbot Logs Table
CREATE TABLE IF NOT EXISTS `chatbot_logs` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL DEFAULT 0,
    `user_role` VARCHAR(50) DEFAULT 'guest',
    `query` TEXT NOT NULL,
    `response` TEXT NOT NULL,
    `model` VARCHAR(100) DEFAULT 'llama-3.1-70b-versatile',
    `tokens_used` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
