<?php
/**
 * AI Chatbot API - EduSys
 * Handles chat requests via Groq API
 */
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../config/ai.php';

header('Content-Type: application/json');

// Only accept POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'msg' => 'Method not allowed']);
    exit;
}

// Get input
$input = json_decode(file_get_contents('php://input'), true);
$message = trim($input['message'] ?? '');
$context = $input['context'] ?? []; // Previous messages for conversation history

if (!$message) {
    echo json_encode(['success' => false, 'msg' => 'Message required']);
    exit;
}

// Get user info for context
$userId = $_SESSION['user_id'] ?? 0;
$userRole = $_SESSION['role'] ?? 'guest';
$userName = $_SESSION['name'] ?? 'User';

// Build system prompt with context about EduSys
$systemPrompt = buildSystemPrompt($userRole, $userName);

// Build conversation history
$messages = [
    ['role' => 'system', 'content' => $systemPrompt]
];

// Add conversation history (last 10 messages)
$history = array_slice($context, -10);
foreach ($history as $msg) {
    if (isset($msg['role']) && isset($msg['content'])) {
        $messages[] = ['role' => $msg['role'], 'content' => $msg['content']];
    }
}

// Add current user message
$messages[] = ['role' => 'user', 'content' => $message];

// Call Groq API
$response = callGroqAPI($messages);

echo json_encode($response);

function callGroqAPI($messages) {
    $apiKey = GROQ_API_KEY;
    $model = GROQ_MODEL;
    $url = 'https://api.groq.com/openai/v1/chat/completions';

    $data = [
        'model' => $model,
        'messages' => $messages,
        'max_tokens' => 500,
        'temperature' => 0.7,
        'reasoning_effort' => 'low'
    ];

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($data),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $apiKey
        ],
        CURLOPT_TIMEOUT => 30,
        CURLOPT_SSL_VERIFYPEER => false
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    if ($error) {
        return ['success' => false, 'msg' => 'API connection failed: ' . $error];
    }

    $result = json_decode($response, true);

    if ($httpCode !== 200) {
        $msg = $result['error']['message'] ?? 'API error';
        return ['success' => false, 'msg' => 'Groq API error: ' . $msg];
    }

    $content = $result['choices'][0]['message']['content'] ?? '';

    return ['success' => true, 'reply' => trim($content)];
}

function buildSystemPrompt($role, $name) {
    $roleContext = '';
    switch ($role) {
        case 'teacher':
            $roleContext = "You are helping a TEACHER named $name. They can ask about: creating/managing classes, taking attendance, grading, assignments, exams, student management, live classes, screen sharing, recordings, and teacher dashboard features.";
            break;
        case 'student':
            $roleContext = "You are helping a STUDENT named $name. They can ask about: joining live classes, viewing recordings, submitting assignments, checking attendance, viewing grades, schedule, materials, doubts, and student dashboard features.";
            break;
        case 'parent':
            $roleContext = "You are helping a PARENT named $name. They can ask about: child's attendance, grades, schedule, fees, live classes, recordings, and parent dashboard features.";
            break;
        case 'admin':
            $roleContext = "You are helping an ADMIN named $name. They can ask about: system management, user management, reports, analytics, live class monitoring, and admin dashboard features.";
            break;
        default:
            $roleContext = "You are helping a user named $name.";
    }

    return <<<PROMPT
You are EduBot, the AI assistant for EduSys - an educational management system.

$roleContext

EDUSYS FEATURES YOU KNOW:
- Live Classes: Join via live_class_room.php, screen sharing, recording (auto for teachers), quality settings (320p/720p/1080p)
- Recordings: Auto-saved to uploads/recordings/, named {Class_Name}_{Date_Time}.webm, viewable in recorded_classes.php
- Attendance: Auto-tracked when joining live classes, percentage calculated
- Assignments: Teachers create, students submit, teachers grade
- Exams: Teachers create, students take, results shown
- Materials: Teachers upload, students download
- Doubts: Students ask, teachers reply
- Chat: In live classes and messaging system
- Dashboard: Role-specific (student/teacher/parent/admin)
- Notifications: Real-time for messages, classes, announcements

GUIDELINES:
- Be helpful, concise, and friendly
- Answer questions about EduSys features and education topics
- If asked about a specific feature, explain how to use it step-by-step
- For education questions, provide clear explanations
- Don't make up features that don't exist
- If unsure, suggest checking the relevant dashboard section
- Keep responses under 200 words unless detailed explanation needed

Current user: $name ($role)
PROMPT;
}

function callGroqAPI($messages) {
    $apiKey = GROQ_API_KEY;
    $model = GROQ_MODEL;
    $url = 'https://api.groq.com/openai/v1/chat/completions';

    $data = [
        'model' => $model,
        'messages' => $messages,
        'max_tokens' => 500,
        'temperature' => 0.7,
        'reasoning_effort' => 'low'
    ];

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($data),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $apiKey
        ],
        CURLOPT_TIMEOUT => 30,
        CURLOPT_SSL_VERIFYPEER => false
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    if ($error) {
        return ['success' => false, 'msg' => 'API connection failed: ' . $error];
    }

    $result = json_decode($response, true);

    if ($httpCode !== 200) {
        $msg = $result['error']['message'] ?? 'API error';
        return ['success' => false, 'msg' => 'Groq API error: ' . $msg];
    }

    $content = $result['choices'][0]['message']['content'] ?? '';

    // Clean up reasoning if present
    if (isset($result['choices'][0]['message']['reasoning'])) {
        // Content is clean, reasoning is separate
    }

    return ['success' => true, 'reply' => trim($content)];
}