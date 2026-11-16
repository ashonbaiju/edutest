<?php
session_start();

// Load config first to get the correct BASE_URL definition
require_once __DIR__ . '/../config/db.php';

// Ensure BASE_URL is defined (fallback just in case)
if (!defined('BASE_URL')) {
    define('BASE_URL', '/project/');
}

// ── Self-contained EduBot AI API (bypasses InfinityFree standalone endpoint blocking) ──
if (isset($_POST['action']) && $_POST['action'] === 'edubot_chat') {
    require_once __DIR__ . '/ai_engine.php';
    header('Content-Type: application/json; charset=UTF-8');
    header('Access-Control-Allow-Origin: *');

    $message = trim($_POST['message'] ?? '');
    $rawContext = $_POST['context'] ?? null;
    if (!empty($_POST['context_b64'])) {
        $decoded = @base64_decode($_POST['context_b64']);
        if ($decoded) {
            $rawContext = json_decode($decoded, true) ?: $rawContext;
        }
    }
    if (is_string($rawContext)) {
        $rawContext = json_decode($rawContext, true) ?: [];
    }
    $context = is_array($rawContext) ? $rawContext : [];

    if ($message === '') {
        echo json_encode(['success' => false, 'msg' => 'Message is required.']);
        exit;
    }

    $userId = (int)($_SESSION['user_id'] ?? 0);
    $userRole = $_SESSION['role'] ?? 'guest';
    $userName = $_SESSION['name'] ?? 'Guest';

    $response = executeAiChat($message, $context, $userRole, $userName, $conn ?? null, $userId);
    echo json_encode($response);
    exit;
}

function isLoggedIn() {
    return isset($_SESSION['user_id']);
}

function requireLogin() {
    if (!isLoggedIn()) {
        header('Location: ' . BASE_URL . 'login.php');
        exit;
    }
}

function requireRole($role) {
    requireLogin();
    if ($_SESSION['role'] !== $role) {
        header('Location: ' . BASE_URL . 'unauthorized.php');
        exit;
    }
}

function isAdmin() { return isset($_SESSION['role']) && $_SESSION['role'] === 'admin'; }
function isTeacher() { return isset($_SESSION['role']) && $_SESSION['role'] === 'teacher'; }
function isStudent() { return isset($_SESSION['role']) && $_SESSION['role'] === 'student'; }
function isParent() { return isset($_SESSION['role']) && $_SESSION['role'] === 'parent'; }

function redirectByRole() {
    if (!isset($_SESSION['role'])) {
        header('Location: ' . BASE_URL . 'login.php');
        exit;
    }
    switch ($_SESSION['role']) {
        case 'admin':
            header('Location: ' . BASE_URL . 'admin/dashboard.php');
            break;
        case 'teacher':
            header('Location: ' . BASE_URL . 'teacher/dashboard.php');
            break;
        case 'student':
            header('Location: ' . BASE_URL . 'student/dashboard.php');
            break;
        case 'parent':
            header('Location: ' . BASE_URL . 'parent/dashboard.php');
            break;
        default:
            header('Location: ' . BASE_URL . 'login.php');
            break;
    }
    exit;
}
?>
