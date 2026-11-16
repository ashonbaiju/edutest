-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 15, 2026 at 11:44 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tuition_system`
--
-- Note: Select your database (e.g. if0_xxxx_edusys on InfinityFree) before importing this file
-- CREATE DATABASE IF NOT EXISTS `tuition_system` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE `tuition_system`;

-- --------------------------------------------------------

--
-- Table structure for table `admission_requests`
--

CREATE TABLE `admission_requests` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `batch_id` int(11) NOT NULL,
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `admin_remarks` text DEFAULT NULL,
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `admission_requests`
--

INSERT INTO `admission_requests` (`id`, `student_id`, `batch_id`, `status`, `admin_remarks`, `requested_at`) VALUES
(1, 1, 2, 'approved', 'Approved by teacher', '2026-05-26 17:59:14');

-- --------------------------------------------------------

--
-- Table structure for table `assignments`
--

CREATE TABLE `assignments` (
  `id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `due_date` datetime DEFAULT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `attendance`
--

CREATE TABLE `attendance` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `date` date NOT NULL,
  `status` enum('present','absent','late') DEFAULT 'present',
  `marked_by` int(11) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `attendance`
--

INSERT INTO `attendance` (`id`, `student_id`, `batch_id`, `date`, `status`, `marked_by`, `remarks`, `created_at`) VALUES
(1, 1, 2, '2026-05-26', 'present', 2, NULL, '2026-05-26 18:14:08');

-- --------------------------------------------------------

--
-- Table structure for table `batches`
--

CREATE TABLE `batches` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `teacher_id` int(11) DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `grade` varchar(20) DEFAULT NULL,
  `schedule` text DEFAULT NULL,
  `max_students` int(11) DEFAULT 30,
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `batches`
--

INSERT INTO `batches` (`id`, `name`, `teacher_id`, `subject_id`, `grade`, `schedule`, `max_students`, `status`, `created_at`) VALUES
(1, 'Mathematics Batch A', 1, 6, '10', 'Mon/Wed 4:00 PM', 30, 'active', '2026-05-26 17:56:36'),
(2, 'Calculus Advanced Batch', 1, 6, '12', 'Tue/Thu 5:00 PM', 25, 'active', '2026-05-26 17:56:36');

-- --------------------------------------------------------

--
-- Table structure for table `batch_students`
--

CREATE TABLE `batch_students` (
  `id` int(11) NOT NULL,
  `batch_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `enrolled_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `batch_students`
--

INSERT INTO `batch_students` (`id`, `batch_id`, `student_id`, `enrolled_at`) VALUES
(5, 2, 1, '2026-05-26 17:59:35');

-- --------------------------------------------------------

--
-- Table structure for table `bookmarks`
--

CREATE TABLE `bookmarks` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `material_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `complaints`
--

CREATE TABLE `complaints` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `against_user_id` int(11) DEFAULT NULL,
  `subject` varchar(200) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `status` enum('open','in_review','resolved','closed') DEFAULT 'open',
  `admin_response` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `doubts`
--

CREATE TABLE `doubts` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `teacher_id` int(11) DEFAULT NULL,
  `title` varchar(200) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `status` enum('open','answered','closed') DEFAULT 'open',
  `answered_by` int(11) DEFAULT NULL,
  `answer` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exams`
--

CREATE TABLE `exams` (
  `id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `exam_date` date DEFAULT NULL,
  `total_marks` int(11) DEFAULT 100,
  `pass_marks` int(11) DEFAULT 40,
  `exam_type` enum('unit_test','mid_term','final','practice') DEFAULT 'unit_test',
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `feedback`
--

CREATE TABLE `feedback` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `target_user_id` int(11) DEFAULT NULL,
  `target_type` enum('teacher','course','platform') DEFAULT 'platform',
  `rating` int(11) DEFAULT 5,
  `comment` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `fees`
--

CREATE TABLE `fees` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `paid_date` date DEFAULT NULL,
  `status` enum('paid','unpaid','partial','overdue') DEFAULT 'unpaid',
  `payment_method` varchar(50) DEFAULT NULL,
  `transaction_id` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `forum_posts`
--

CREATE TABLE `forum_posts` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `content` text NOT NULL,
  `category` varchar(100) DEFAULT 'General',
  `likes` int(11) DEFAULT 0,
  `replies_count` int(11) DEFAULT 0,
  `is_pinned` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `forum_posts`
--

INSERT INTO `forum_posts` (`id`, `user_id`, `title`, `content`, `category`, `likes`, `replies_count`, `is_pinned`, `created_at`) VALUES
(1, 3, 'Tips for Calculus?', 'Can anyone share good tips for understanding integration by parts?', 'Academic', 0, 0, 0, '2026-05-25 15:09:08'),
(2, 2, 'Online class schedule for next week', 'Sharing the updated schedule for Monday Math class.', 'Announcements', 0, 0, 0, '2026-05-25 15:09:08');

-- --------------------------------------------------------

--
-- Table structure for table `forum_replies`
--

CREATE TABLE `forum_replies` (
  `id` int(11) NOT NULL,
  `post_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `content` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `helpdesk_tickets`
--

CREATE TABLE `helpdesk_tickets` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `subject` varchar(200) NOT NULL,
  `message` text NOT NULL,
  `status` enum('open','in_progress','resolved','closed') DEFAULT 'open',
  `admin_response` text DEFAULT NULL,
  `priority` enum('low','medium','high') DEFAULT 'medium',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `helpdesk_tickets`
--

INSERT INTO `helpdesk_tickets` (`id`, `user_id`, `subject`, `message`, `status`, `admin_response`, `priority`, `created_at`, `updated_at`) VALUES
(1, 3, 'Cannot access study materials', 'I am unable to download the study materials for Mathematics. Please help.', 'open', NULL, 'medium', '2026-05-25 15:09:08', '2026-05-25 15:09:08'),
(2, 2, 'Salary not yet credited', 'My salary for March 2026 has not been credited to my account.', 'open', NULL, 'medium', '2026-05-25 15:09:08', '2026-05-25 15:09:08'),
(3, 3, 'Cannot access study materials', 'I am unable to download study materials from the materials page.', 'open', NULL, 'medium', '2026-05-25 15:09:17', '2026-05-25 15:09:17'),
(4, 2, 'Salary payment issue', 'My salary for March has not been credited yet. Please look into this.', 'open', NULL, 'high', '2026-05-25 15:09:17', '2026-05-25 15:09:17');

-- --------------------------------------------------------

--
-- Table structure for table `live_attendance`
--

CREATE TABLE `live_attendance` (
  `id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `join_time` datetime DEFAULT NULL,
  `leave_time` datetime DEFAULT NULL,
  `duration` int(11) DEFAULT 0 COMMENT 'in seconds',
  `percentage` decimal(5,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `live_attendance`
--

INSERT INTO `live_attendance` (`id`, `class_id`, `student_id`, `join_time`, `leave_time`, `duration`, `percentage`) VALUES
(1, 1, 1, '2026-05-26 20:51:20', '2026-05-26 20:52:59', -12501, -347.25),
(2, 2, 1, '2026-05-26 20:54:53', '2026-05-26 20:55:43', -12550, -348.61),
(3, 4, 1, '2026-05-26 22:33:39', '2026-05-26 22:37:00', -12399, -344.42),
(4, 6, 1, '2026-05-26 22:37:07', '2026-05-26 23:19:04', -10083, -280.08),
(5, 7, 1, '2026-05-26 23:41:01', '2026-05-26 23:43:32', -12449, -345.81),
(6, 8, 1, '2026-11-14 11:25:40', '2026-11-14 11:25:49', -16191, -449.75),
(7, 10, 1, '2026-11-14 21:32:00', '2026-11-14 22:17:12', -13488, -749.33),
(8, 11, 1, '2026-11-14 22:19:29', '2026-11-14 22:19:56', -16173, -599.00),
(9, 12, 1, '2026-11-14 22:48:38', '2026-11-14 22:48:57', -16181, -449.47),
(10, 13, 1, '2026-11-14 23:15:06', '2026-11-14 23:17:01', -16085, -893.61),
(11, 14, 1, '2026-11-15 15:57:06', '2026-11-15 15:57:47', -16159, -897.72);

-- --------------------------------------------------------

--
-- Table structure for table `live_classes`
--

CREATE TABLE `live_classes` (
  `id` int(11) NOT NULL,
  `title` varchar(200) DEFAULT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `teacher_id` int(11) DEFAULT NULL,
  `room_id` varchar(100) DEFAULT NULL,
  `scheduled_at` datetime DEFAULT NULL,
  `duration_minutes` int(11) DEFAULT 60,
  `status` enum('scheduled','live','ended') DEFAULT 'scheduled',
  `recording_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `end_time` datetime DEFAULT NULL,
  `start_time` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `live_classes`
--

INSERT INTO `live_classes` (`id`, `title`, `batch_id`, `teacher_id`, `room_id`, `scheduled_at`, `duration_minutes`, `status`, `recording_url`, `created_at`, `end_time`, `start_time`) VALUES
(1, 'rtrf', 0, 1, 'room-6a15ba343bd1d', '2026-05-26 20:50:00', 60, 'ended', 'uploads/recordings/class_1_1779808966.webm', '2026-05-26 15:20:20', '2026-05-26 20:53:34', '2026-05-26 20:50:22'),
(2, 'ty', 0, 1, 'room-6a15bb19bed85', '2026-05-26 20:54:00', 60, 'ended', NULL, '2026-05-26 15:24:09', '2026-05-26 20:55:43', '2026-05-26 20:54:23'),
(3, 'eqwr', 0, 1, 'room-6a15be5f7148b', '2026-05-26 21:08:00', 60, 'ended', NULL, '2026-05-26 15:38:07', '2026-05-26 21:08:29', '2026-05-26 21:08:09'),
(4, 'ewr', 0, 1, 'room-6a15c1ca95634', '2026-05-26 21:22:00', 60, 'ended', NULL, '2026-05-26 15:52:42', '2026-05-26 23:47:43', '2026-05-26 21:22:44'),
(5, 'rfcfr', 0, 1, 'room-6a15cb3172e57', '2026-05-26 22:02:00', 60, 'ended', NULL, '2026-05-26 16:32:49', '2026-05-26 22:06:48', '2026-05-26 22:03:01'),
(6, 'wedrx', 0, 1, 'room-6a15cc4a8f07e', '2026-05-26 22:07:00', 60, 'ended', NULL, '2026-05-26 16:37:30', '2026-05-26 23:19:04', '2026-05-26 22:07:32'),
(7, 'uyttth', 0, 1, 'room-6a15dfa0a12d4', '2026-05-26 23:29:00', 60, 'ended', NULL, '2026-05-26 18:00:00', '2026-05-26 23:43:32', '2026-05-26 23:30:02'),
(8, 'wedsz', 0, 1, 'room-6a15e58999755', '2026-05-26 23:55:00', 60, 'ended', NULL, '2026-05-26 18:25:13', '2026-11-14 19:55:04', '2026-05-26 23:55:15'),
(9, 'test1', 1, 1, 'room-6af86e3ddcb55', '2026-11-14 19:50:00', 30, 'ended', NULL, '2026-11-14 14:20:45', '2026-11-14 19:52:41', '2026-11-14 19:50:48'),
(10, 'tese2', 0, 1, 'room-6af86f5385399', '2026-11-14 19:55:00', 30, 'ended', NULL, '2026-11-14 14:25:23', '2026-11-14 22:17:17', '2026-11-14 19:55:25'),
(11, 'test3', 0, 1, 'room-6af891147f8b3', '2026-11-14 22:19:00', 45, 'ended', NULL, '2026-11-14 16:49:24', '2026-11-14 22:20:01', '2026-11-14 22:19:25'),
(12, 'test4', 0, 1, 'room-6af897e571ee9', '2026-11-14 22:48:00', 60, 'ended', 'uploads/recordings/test4_2026-11-14_17-18-35.webm', '2026-11-14 17:18:29', '2026-11-14 22:49:04', '2026-11-14 22:48:34'),
(13, 'text5', 0, 1, 'room-6af89e0dc9553', '2026-11-14 23:14:00', 30, 'ended', 'uploads/recordings/text5_2026-11-14_17-46-48.webm', '2026-11-14 17:44:45', '2026-11-14 23:17:01', '2026-11-14 23:14:47'),
(14, 'test6', 0, 1, 'room-6af988e173bef', '2026-11-15 15:56:00', 30, 'ended', 'uploads/recordings/test6_2026-11-15_10-26-52.webm', '2026-11-15 10:26:41', '2026-11-15 15:57:57', '2026-11-15 15:56:46'),
(15, 'test7', 0, 1, 'room-6af989a0b99b8', '2026-11-15 15:59:00', 45, 'ended', 'uploads/recordings/test7_2026-11-15_10-29-55.webm', '2026-11-15 10:29:52', '2026-11-15 16:01:21', '2026-11-15 15:59:54');

-- --------------------------------------------------------

--
-- Table structure for table `live_doubts`
--

CREATE TABLE `live_doubts` (
  `id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `question` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `live_doubt_replies`
--

CREATE TABLE `live_doubt_replies` (
  `id` int(11) NOT NULL,
  `doubt_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `reply` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `live_messages`
--

CREATE TABLE `live_messages` (
  `id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `live_messages`
--

INSERT INTO `live_messages` (`id`, `class_id`, `user_id`, `message`, `created_at`) VALUES
(1, 1, 3, 'hi', '2026-05-26 15:21:34'),
(2, 1, 2, 'aloe', '2026-05-26 15:21:41'),
(3, 2, 2, 'ghy', '2026-05-26 15:24:31'),
(4, 2, 3, 'hi', '2026-05-26 15:25:19'),
(5, 8, 3, 'hi', '2026-11-14 14:22:14'),
(6, 8, 3, 'hii', '2026-11-14 14:24:16'),
(7, 8, 2, 'hii', '2026-11-14 14:24:26');

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` int(11) NOT NULL,
  `sender_id` int(11) NOT NULL,
  `receiver_id` int(11) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `sent_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notices`
--

CREATE TABLE `notices` (
  `id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `content` text DEFAULT NULL,
  `target_role` enum('all','student','teacher','admin') DEFAULT 'all',
  `batch_id` int(11) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `is_pinned` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notices`
--

INSERT INTO `notices` (`id`, `title`, `content`, `target_role`, `batch_id`, `created_by`, `is_pinned`, `created_at`) VALUES
(1, 'Welcome to EduSys!', 'Welcome to the AI-powered tuition system.', 'all', NULL, 1, 1, '2026-05-25 15:01:43'),
(2, 'Fee Reminder', 'Please pay fees before month end.', 'student', NULL, 1, 0, '2026-05-25 15:01:43'),
(3, 'test', 'test', 'all', NULL, 1, 0, '2026-05-25 15:56:05'),
(4, 'lhio', 'giyuy', '', NULL, 2, 0, '2026-05-26 15:16:48'),
(5, 'rfg', 'fg', 'all', NULL, 1, 0, '2026-05-26 15:19:01');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(200) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `type` varchar(50) DEFAULT 'info',
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `type`, `is_read`, `created_at`) VALUES
(1, 3, 'Enrollment Approved', 'Your request to join a batch has been approved by the teacher!', 'success', 1, '2026-05-26 17:59:35');

-- --------------------------------------------------------

--
-- Table structure for table `packages`
--

CREATE TABLE `packages` (
  `id` int(11) NOT NULL,
  `name` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `duration_months` int(11) DEFAULT NULL,
  `type` enum('all_subjects','specific_subject','extracurricular') DEFAULT 'all_subjects',
  `teacher_id` int(11) DEFAULT NULL,
  `subject_ids` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `payout_requests`
--

CREATE TABLE `payout_requests` (
  `id` int(11) NOT NULL,
  `teacher_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `bank_details` text DEFAULT NULL,
  `status` enum('pending','approved','paid','rejected') DEFAULT 'pending',
  `admin_note` text DEFAULT NULL,
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `recordings`
--

CREATE TABLE `recordings` (
  `id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `file_path` varchar(500) NOT NULL,
  `file_size` bigint(20) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `recordings`
--

INSERT INTO `recordings` (`id`, `class_id`, `file_path`, `file_size`, `created_at`) VALUES
(1, 1, 'uploads/recordings/class_1_1779808966.webm', 5427, '2026-05-26 15:22:46'),
(2, 12, 'uploads/recordings/test4_2026-11-14_17-18-35.webm', 2509436, '2026-11-14 17:19:01'),
(3, 13, 'uploads/recordings/text5_2026-11-14_17-44-48.webm', 611764, '2026-11-14 17:44:54'),
(4, 13, 'uploads/recordings/text5_2026-11-14_17-44-54.webm', 3559276, '2026-11-14 17:45:27'),
(5, 13, 'uploads/recordings/text5_2026-11-14_17-45-27.webm', 215217, '2026-11-14 17:45:30'),
(6, 13, 'uploads/recordings/text5_2026-11-14_17-45-30.webm', 125186, '2026-11-14 17:45:32'),
(7, 13, 'uploads/recordings/text5_2026-11-14_17-45-33.webm', 119586, '2026-11-14 17:45:34'),
(8, 13, 'uploads/recordings/class_13_1794678356070.webm', 1720135, '2026-11-14 17:45:56'),
(9, 13, 'uploads/recordings/text5_2026-11-14_17-45-35.webm', 2286038, '2026-11-14 17:45:56'),
(10, 13, 'uploads/recordings/class_13_1794678367116.webm', 1078023, '2026-11-14 17:46:07'),
(11, 13, 'uploads/recordings/text5_2026-11-14_17-45-57.webm', 1012590, '2026-11-14 17:46:07'),
(12, 13, 'uploads/recordings/class_13_1794678370476.webm', 231352, '2026-11-14 17:46:10'),
(13, 13, 'uploads/recordings/text5_2026-11-14_17-46-08.webm', 196190, '2026-11-14 17:46:11'),
(14, 13, 'uploads/recordings/class_13_1794678374837.webm', 335817, '2026-11-14 17:46:14'),
(15, 13, 'uploads/recordings/text5_2026-11-14_17-46-11.webm', 310911, '2026-11-14 17:46:15'),
(16, 13, 'uploads/recordings/class_13_1794678391620.webm', 2100177, '2026-11-14 17:46:31'),
(17, 13, 'uploads/recordings/text5_2026-11-14_17-46-15.webm', 1983444, '2026-11-14 17:46:32'),
(18, 13, 'uploads/recordings/class_13_1794678396418.webm', 680066, '2026-11-14 17:46:36'),
(19, 13, 'uploads/recordings/text5_2026-11-14_17-46-32.webm', 601183, '2026-11-14 17:46:36'),
(20, 13, 'uploads/recordings/class_13_1794678405209.webm', 1395042, '2026-11-14 17:46:45'),
(21, 13, 'uploads/recordings/text5_2026-11-14_17-46-37.webm', 1767859, '2026-11-14 17:46:48'),
(22, 13, 'uploads/recordings/text5_2026-11-14_17-46-48.webm', 887215, '2026-11-14 17:46:58'),
(23, 14, 'uploads/recordings/test6_2026-11-15_10-26-52.webm', 2042052, '2026-11-15 10:27:54'),
(24, 15, 'uploads/recordings/test7_2026-11-15_10-29-55.webm', 8434643, '2026-11-15 10:31:18');

-- --------------------------------------------------------

--
-- Table structure for table `results`
--

CREATE TABLE `results` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `marks_obtained` decimal(5,2) DEFAULT 0.00,
  `grade_letter` varchar(5) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `salary`
--

CREATE TABLE `salary` (
  `id` int(11) NOT NULL,
  `teacher_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `month` varchar(20) DEFAULT NULL,
  `year` int(11) DEFAULT NULL,
  `paid_date` date DEFAULT NULL,
  `status` enum('paid','pending') DEFAULT 'pending',
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `salary_requests`
--

CREATE TABLE `salary_requests` (
  `id` int(11) NOT NULL,
  `teacher_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `reason` text DEFAULT NULL,
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `admin_remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `schedules`
--

CREATE TABLE `schedules` (
  `id` int(11) NOT NULL,
  `teacher_id` int(11) NOT NULL,
  `batch_id` int(11) DEFAULT NULL,
  `title` varchar(200) DEFAULT NULL,
  `day_of_week` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `location` varchar(200) DEFAULT 'Online',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

CREATE TABLE `students` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `roll_number` varchar(50) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `gender` enum('male','female','other') DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `parent_name` varchar(150) DEFAULT NULL,
  `parent_phone` varchar(20) DEFAULT NULL,
  `grade` varchar(20) DEFAULT NULL,
  `admission_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `students`
--

INSERT INTO `students` (`id`, `user_id`, `roll_number`, `date_of_birth`, `gender`, `phone`, `address`, `parent_name`, `parent_phone`, `grade`, `admission_date`) VALUES
(1, 3, 'STU0001', NULL, NULL, '9876543211', NULL, 'Demo Parent', NULL, 'Grade 10', '2026-05-25');

-- --------------------------------------------------------

--
-- Table structure for table `study_materials`
--

CREATE TABLE `study_materials` (
  `id` int(11) NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `subject_id` int(11) DEFAULT NULL,
  `uploaded_by` int(11) DEFAULT NULL,
  `type` enum('pdf','video','image','link') DEFAULT 'pdf',
  `download_count` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

CREATE TABLE `subjects` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `code` varchar(20) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `subjects`
--

INSERT INTO `subjects` (`id`, `name`, `code`, `description`, `created_at`) VALUES
(1, 'Mathematics', 'MATH101', NULL, '2026-05-25 15:01:42'),
(2, 'Physics', 'PHY101', NULL, '2026-05-25 15:01:42'),
(3, 'Chemistry', 'CHEM101', NULL, '2026-05-25 15:01:42'),
(4, 'English', 'ENG101', NULL, '2026-05-25 15:01:42'),
(5, 'Computer Science', 'CS101', NULL, '2026-05-25 15:01:42'),
(6, 'Biology', 'BIO101', NULL, '2026-05-25 15:01:42'),
(7, 'History', 'HIST101', NULL, '2026-05-25 15:01:42'),
(8, 'Economics', 'ECO101', NULL, '2026-05-25 15:01:42');

-- --------------------------------------------------------

--
-- Table structure for table `submissions`
--

CREATE TABLE `submissions` (
  `id` int(11) NOT NULL,
  `assignment_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `marks` decimal(5,2) DEFAULT NULL,
  `submitted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('submitted','graded','late') DEFAULT 'submitted'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `teachers`
--

CREATE TABLE `teachers` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `qualification` varchar(255) DEFAULT NULL,
  `specialization` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` text DEFAULT NULL,
  `gender` enum('male','female','other') DEFAULT NULL,
  `experience_years` int(11) DEFAULT 0,
  `salary` decimal(10,2) DEFAULT 0.00,
  `document_path` varchar(255) DEFAULT NULL,
  `approval_status` enum('pending','approved','rejected') DEFAULT 'approved',
  `joined_date` date DEFAULT NULL,
  `rating` decimal(3,2) DEFAULT 0.00,
  `verification_status` enum('pending_submission','submitted','verified','rejected') DEFAULT 'pending_submission',
  `aadhar_number` varchar(20) DEFAULT NULL,
  `aadhar_file` varchar(255) DEFAULT NULL,
  `certificate_file` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `teachers`
--

INSERT INTO `teachers` (`id`, `user_id`, `qualification`, `specialization`, `phone`, `address`, `gender`, `experience_years`, `salary`, `document_path`, `approval_status`, `joined_date`, `rating`, `verification_status`, `aadhar_number`, `aadhar_file`, `certificate_file`) VALUES
(1, 2, 'M.Sc Mathematics', 'Mathematics, Physics', '9876543210', 'iyygyi', NULL, 5, 35000.00, NULL, 'approved', NULL, 0.00, 'verified', 'tdrtr', 'aadhar_2_1779808536.png', 'cert_2_1779808536.png');

-- --------------------------------------------------------

--
-- Table structure for table `teacher_attendance`
--

CREATE TABLE `teacher_attendance` (
  `id` int(11) NOT NULL,
  `teacher_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `status` enum('present','absent','late') DEFAULT 'present',
  `marked_by` int(11) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `test_attempts`
--

CREATE TABLE `test_attempts` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `answers` text DEFAULT NULL,
  `score` decimal(5,2) DEFAULT 0.00,
  `total_questions` int(11) DEFAULT 0,
  `submitted_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `test_questions`
--

CREATE TABLE `test_questions` (
  `id` int(11) NOT NULL,
  `exam_id` int(11) NOT NULL,
  `question` text NOT NULL,
  `option_a` varchar(300) DEFAULT NULL,
  `option_b` varchar(300) DEFAULT NULL,
  `option_c` varchar(300) DEFAULT NULL,
  `option_d` varchar(300) DEFAULT NULL,
  `correct_answer` enum('a','b','c','d') DEFAULT NULL,
  `marks` int(11) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `type` enum('fee_payment','salary','refund','other') DEFAULT 'fee_payment',
  `description` varchar(255) DEFAULT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `status` enum('success','pending','failed') DEFAULT 'success',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(150) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','teacher','student') NOT NULL DEFAULT 'student',
  `avatar` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive','pending') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password`, `role`, `avatar`, `status`, `created_at`, `updated_at`) VALUES
(1, 'System Admin', 'admin@edusys.com', '$2y$10$7Wx5CP3pi9kXSTmJ7i.is.Pl/eANRxEQ/jCa3zHfTScbIjNsJL8VK', 'admin', NULL, 'active', '2026-05-25 15:01:43', '2026-05-25 16:51:45'),
(2, 'Demo Teacher', 'teacher@edusys.com', '$2y$10$7Wx5CP3pi9kXSTmJ7i.is.Pl/eANRxEQ/jCa3zHfTScbIjNsJL8VK', 'teacher', NULL, 'active', '2026-05-25 15:01:43', '2026-05-25 15:01:43'),
(3, 'Demo Student', 'student@edusys.com', '$2y$10$7Wx5CP3pi9kXSTmJ7i.is.Pl/eANRxEQ/jCa3zHfTScbIjNsJL8VK', 'student', NULL, 'active', '2026-05-25 15:01:43', '2026-05-25 15:01:43');

-- --------------------------------------------------------

--
-- Table structure for table `webrtc_peers`
--

CREATE TABLE `webrtc_peers` (
  `id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `user_name` varchar(150) DEFAULT NULL,
  `user_role` varchar(20) DEFAULT NULL,
  `last_ping` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `webrtc_signals`
--

CREATE TABLE `webrtc_signals` (
  `id` int(11) NOT NULL,
  `class_id` int(11) NOT NULL,
  `from_user` int(11) NOT NULL,
  `to_user` int(11) NOT NULL,
  `signal_type` varchar(20) NOT NULL,
  `signal_data` longtext NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admission_requests`
--
ALTER TABLE `admission_requests`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `assignments`
--
ALTER TABLE `assignments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `attendance`
--
ALTER TABLE `attendance`
  ADD PRIMARY KEY (`id`),
  ADD KEY `student_id` (`student_id`);

--
-- Indexes for table `batches`
--
ALTER TABLE `batches`
  ADD PRIMARY KEY (`id`),
  ADD KEY `teacher_id` (`teacher_id`),
  ADD KEY `subject_id` (`subject_id`);

--
-- Indexes for table `batch_students`
--
ALTER TABLE `batch_students`
  ADD PRIMARY KEY (`id`),
  ADD KEY `batch_id` (`batch_id`),
  ADD KEY `student_id` (`student_id`);

--
-- Indexes for table `bookmarks`
--
ALTER TABLE `bookmarks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `material_id` (`material_id`);

--
-- Indexes for table `complaints`
--
ALTER TABLE `complaints`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `doubts`
--
ALTER TABLE `doubts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `teacher_id` (`teacher_id`);

--
-- Indexes for table `exams`
--
ALTER TABLE `exams`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `feedback`
--
ALTER TABLE `feedback`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `fees`
--
ALTER TABLE `fees`
  ADD PRIMARY KEY (`id`),
  ADD KEY `student_id` (`student_id`);

--
-- Indexes for table `forum_posts`
--
ALTER TABLE `forum_posts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `forum_replies`
--
ALTER TABLE `forum_replies`
  ADD PRIMARY KEY (`id`),
  ADD KEY `post_id` (`post_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `helpdesk_tickets`
--
ALTER TABLE `helpdesk_tickets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `live_attendance`
--
ALTER TABLE `live_attendance`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_attendance` (`class_id`,`student_id`),
  ADD KEY `student_id` (`student_id`);

--
-- Indexes for table `live_classes`
--
ALTER TABLE `live_classes`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `room_id` (`room_id`);

--
-- Indexes for table `live_doubts`
--
ALTER TABLE `live_doubts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `class_id` (`class_id`),
  ADD KEY `student_id` (`student_id`);

--
-- Indexes for table `live_doubt_replies`
--
ALTER TABLE `live_doubt_replies`
  ADD PRIMARY KEY (`id`),
  ADD KEY `doubt_id` (`doubt_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `live_messages`
--
ALTER TABLE `live_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `class_id` (`class_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sender_id` (`sender_id`),
  ADD KEY `receiver_id` (`receiver_id`);

--
-- Indexes for table `notices`
--
ALTER TABLE `notices`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_notices_batch` (`batch_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `packages`
--
ALTER TABLE `packages`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payout_requests`
--
ALTER TABLE `payout_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `teacher_id` (`teacher_id`);

--
-- Indexes for table `recordings`
--
ALTER TABLE `recordings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `class_id` (`class_id`);

--
-- Indexes for table `results`
--
ALTER TABLE `results`
  ADD PRIMARY KEY (`id`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `exam_id` (`exam_id`);

--
-- Indexes for table `salary`
--
ALTER TABLE `salary`
  ADD PRIMARY KEY (`id`),
  ADD KEY `teacher_id` (`teacher_id`);

--
-- Indexes for table `salary_requests`
--
ALTER TABLE `salary_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `teacher_id` (`teacher_id`);

--
-- Indexes for table `schedules`
--
ALTER TABLE `schedules`
  ADD PRIMARY KEY (`id`),
  ADD KEY `teacher_id` (`teacher_id`),
  ADD KEY `batch_id` (`batch_id`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `roll_number` (`roll_number`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `study_materials`
--
ALTER TABLE `study_materials`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `subjects`
--
ALTER TABLE `subjects`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `submissions`
--
ALTER TABLE `submissions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `assignment_id` (`assignment_id`),
  ADD KEY `student_id` (`student_id`);

--
-- Indexes for table `teachers`
--
ALTER TABLE `teachers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `teacher_attendance`
--
ALTER TABLE `teacher_attendance`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_teacher_date` (`teacher_id`,`date`),
  ADD KEY `marked_by` (`marked_by`);

--
-- Indexes for table `test_attempts`
--
ALTER TABLE `test_attempts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `student_id` (`student_id`),
  ADD KEY `exam_id` (`exam_id`);

--
-- Indexes for table `test_questions`
--
ALTER TABLE `test_questions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `exam_id` (`exam_id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `webrtc_peers`
--
ALTER TABLE `webrtc_peers`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_peer` (`class_id`,`user_id`);

--
-- Indexes for table `webrtc_signals`
--
ALTER TABLE `webrtc_signals`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admission_requests`
--
ALTER TABLE `admission_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `assignments`
--
ALTER TABLE `assignments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `attendance`
--
ALTER TABLE `attendance`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `batches`
--
ALTER TABLE `batches`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `batch_students`
--
ALTER TABLE `batch_students`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `bookmarks`
--
ALTER TABLE `bookmarks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `complaints`
--
ALTER TABLE `complaints`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `doubts`
--
ALTER TABLE `doubts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `exams`
--
ALTER TABLE `exams`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `feedback`
--
ALTER TABLE `feedback`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `fees`
--
ALTER TABLE `fees`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `forum_posts`
--
ALTER TABLE `forum_posts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `forum_replies`
--
ALTER TABLE `forum_replies`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `helpdesk_tickets`
--
ALTER TABLE `helpdesk_tickets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `live_attendance`
--
ALTER TABLE `live_attendance`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `live_classes`
--
ALTER TABLE `live_classes`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `live_doubts`
--
ALTER TABLE `live_doubts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `live_doubt_replies`
--
ALTER TABLE `live_doubt_replies`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `live_messages`
--
ALTER TABLE `live_messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notices`
--
ALTER TABLE `notices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `packages`
--
ALTER TABLE `packages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payout_requests`
--
ALTER TABLE `payout_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `recordings`
--
ALTER TABLE `recordings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `results`
--
ALTER TABLE `results`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `salary`
--
ALTER TABLE `salary`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `salary_requests`
--
ALTER TABLE `salary_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `schedules`
--
ALTER TABLE `schedules`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `students`
--
ALTER TABLE `students`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `study_materials`
--
ALTER TABLE `study_materials`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `subjects`
--
ALTER TABLE `subjects`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `submissions`
--
ALTER TABLE `submissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `teachers`
--
ALTER TABLE `teachers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `teacher_attendance`
--
ALTER TABLE `teacher_attendance`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `test_attempts`
--
ALTER TABLE `test_attempts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `test_questions`
--
ALTER TABLE `test_questions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `webrtc_peers`
--
ALTER TABLE `webrtc_peers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5677;

--
-- AUTO_INCREMENT for table `webrtc_signals`
--
ALTER TABLE `webrtc_signals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=719;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `attendance`
--
ALTER TABLE `attendance`
  ADD CONSTRAINT `attendance_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `batches`
--
ALTER TABLE `batches`
  ADD CONSTRAINT `batches_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`),
  ADD CONSTRAINT `batches_ibfk_2` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`);

--
-- Constraints for table `batch_students`
--
ALTER TABLE `batch_students`
  ADD CONSTRAINT `batch_students_ibfk_1` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `batch_students_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `bookmarks`
--
ALTER TABLE `bookmarks`
  ADD CONSTRAINT `bookmarks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `bookmarks_ibfk_2` FOREIGN KEY (`material_id`) REFERENCES `study_materials` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `complaints`
--
ALTER TABLE `complaints`
  ADD CONSTRAINT `complaints_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `doubts`
--
ALTER TABLE `doubts`
  ADD CONSTRAINT `doubts_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`),
  ADD CONSTRAINT `doubts_ibfk_2` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `feedback`
--
ALTER TABLE `feedback`
  ADD CONSTRAINT `feedback_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `fees`
--
ALTER TABLE `fees`
  ADD CONSTRAINT `fees_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `forum_posts`
--
ALTER TABLE `forum_posts`
  ADD CONSTRAINT `forum_posts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `forum_replies`
--
ALTER TABLE `forum_replies`
  ADD CONSTRAINT `forum_replies_ibfk_1` FOREIGN KEY (`post_id`) REFERENCES `forum_posts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `forum_replies_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `helpdesk_tickets`
--
ALTER TABLE `helpdesk_tickets`
  ADD CONSTRAINT `helpdesk_tickets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `live_attendance`
--
ALTER TABLE `live_attendance`
  ADD CONSTRAINT `live_attendance_ibfk_1` FOREIGN KEY (`class_id`) REFERENCES `live_classes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `live_attendance_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `live_doubts`
--
ALTER TABLE `live_doubts`
  ADD CONSTRAINT `live_doubts_ibfk_1` FOREIGN KEY (`class_id`) REFERENCES `live_classes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `live_doubts_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `live_doubt_replies`
--
ALTER TABLE `live_doubt_replies`
  ADD CONSTRAINT `live_doubt_replies_ibfk_1` FOREIGN KEY (`doubt_id`) REFERENCES `live_doubts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `live_doubt_replies_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `live_messages`
--
ALTER TABLE `live_messages`
  ADD CONSTRAINT `live_messages_ibfk_1` FOREIGN KEY (`class_id`) REFERENCES `live_classes` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `live_messages_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`receiver_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `notices`
--
ALTER TABLE `notices`
  ADD CONSTRAINT `fk_notices_batch` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `payout_requests`
--
ALTER TABLE `payout_requests`
  ADD CONSTRAINT `payout_requests_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `recordings`
--
ALTER TABLE `recordings`
  ADD CONSTRAINT `recordings_ibfk_1` FOREIGN KEY (`class_id`) REFERENCES `live_classes` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `results`
--
ALTER TABLE `results`
  ADD CONSTRAINT `results_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `results_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `salary`
--
ALTER TABLE `salary`
  ADD CONSTRAINT `salary_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `salary_requests`
--
ALTER TABLE `salary_requests`
  ADD CONSTRAINT `salary_requests_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `schedules`
--
ALTER TABLE `schedules`
  ADD CONSTRAINT `schedules_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `schedules_ibfk_2` FOREIGN KEY (`batch_id`) REFERENCES `batches` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `students`
--
ALTER TABLE `students`
  ADD CONSTRAINT `students_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `submissions`
--
ALTER TABLE `submissions`
  ADD CONSTRAINT `submissions_ibfk_1` FOREIGN KEY (`assignment_id`) REFERENCES `assignments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `submissions_ibfk_2` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `teachers`
--
ALTER TABLE `teachers`
  ADD CONSTRAINT `teachers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `teacher_attendance`
--
ALTER TABLE `teacher_attendance`
  ADD CONSTRAINT `teacher_attendance_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `teacher_attendance_ibfk_2` FOREIGN KEY (`marked_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `test_attempts`
--
ALTER TABLE `test_attempts`
  ADD CONSTRAINT `test_attempts_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `test_attempts_ibfk_2` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `test_questions`
--
ALTER TABLE `test_questions`
  ADD CONSTRAINT `test_questions_ibfk_1` FOREIGN KEY (`exam_id`) REFERENCES `exams` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
