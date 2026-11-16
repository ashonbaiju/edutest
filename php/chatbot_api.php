<?php
/**
 * AI Chatbot API - EduSys
 * Handles chat requests via unified AI Engine (Groq, Gemini, DeepSeek, OpenAI)
 */
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Safely attempt DB connection for logging and custom settings
$conn = null;
if (!defined('DONT_DIE_ON_DB_ERROR')) {
    define('DONT_DIE_ON_DB_ERROR', true);
}
if (file_exists(__DIR__ . '/../config/db.php')) {
    mysqli_report(MYSQLI_REPORT_OFF);
    try {
        @include_once __DIR__ . '/../config/db.php';
    } catch (Throwable $t) {
        $conn = null;
    }
}

require_once __DIR__ . '/../includes/ai_engine.php';

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With, Authorization');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'msg' => 'Method not allowed. Use POST.']);
    exit;
}

// Read input from standard POST, base64 context, or JSON payload
$message = trim($_POST['message'] ?? '');
$rawContext = $_POST['context'] ?? null;

if (!empty($_POST['context_b64'])) {
    $decoded = @base64_decode($_POST['context_b64']);
    if ($decoded) {
        $rawContext = json_decode($decoded, true) ?: $rawContext;
    }
}

if ($message === '') {
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);
    if (is_array($input)) {
        $message = trim($input['message'] ?? '');
        $rawContext = $input['context'] ?? $rawContext;
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

// User role & identity from session
$userId = (int)($_SESSION['user_id'] ?? 0);
$userRole = $_SESSION['role'] ?? 'guest';
$userName = $_SESSION['name'] ?? 'Guest';

// Execute AI Chat via Unified Engine
$response = executeAiChat($message, $context, $userRole, $userName, $conn, $userId);

echo json_encode($response);
exit;
