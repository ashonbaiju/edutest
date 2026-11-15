<?php
/**
 * AI Chatbot API - EduSys
 * Handles chat requests via Groq AI with multi-model fallback & educational prompt
 */
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../config/db.php';
if (file_exists(__DIR__ . '/../config/ai.php')) {
    require_once __DIR__ . '/../config/ai.php';
}
if (!defined('GROQ_API_KEY')) {
    define('GROQ_API_KEY', getenv('GROQ_API_KEY') ?: '');
}
if (!defined('GROQ_MODEL')) {
    define('GROQ_MODEL', getenv('GROQ_MODEL') ?: 'openai/gpt-oss-120b');
}
if (!defined('GROQ_FALLBACK_MODELS')) {
    define('GROQ_FALLBACK_MODELS', ['qwen/qwen3.8-27b', 'openai/gpt-oss-20b']);
}

header('Content-Type: application/json; charset=UTF-8');

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'msg' => 'Method not allowed. Use POST.']);
    exit;
}

// Read input JSON
$rawInput = file_get_contents('php://input');
$input = json_decode($rawInput, true);

$message = trim($input['message'] ?? '');
$context = $input['context'] ?? []; // Prior conversation messages

if ($message === '') {
    echo json_encode(['success' => false, 'msg' => 'Message is required.']);
    exit;
}

// User role & identity from session
$userId = $_SESSION['user_id'] ?? 0;
$userRole = $_SESSION['role'] ?? 'guest';
$userName = $_SESSION['name'] ?? 'Guest';

// Build comprehensive system prompt tailored to user and EduSys
$systemPrompt = buildSystemPrompt($userRole, $userName);

// Build messages array
$messages = [
    ['role' => 'system', 'content' => $systemPrompt]
];

// Append clean conversation history (limit to last 8 turns to stay focused)
if (is_array($context)) {
    $recentContext = array_slice($context, -8);
    foreach ($recentContext as $item) {
        if (!empty($item['role']) && !empty($item['content'])) {
            $role = ($item['role'] === 'user') ? 'user' : 'assistant';
            $messages[] = [
                'role' => $role,
                'content' => (string)$item['content']
            ];
        }
    }
}

// Add the latest user message
$messages[] = ['role' => 'user', 'content' => $message];

// Call Groq API with automatic model fallbacks
$response = callGroqWithFallbacks($messages);

echo json_encode($response);
exit;

/**
 * Builds the AI System Prompt with full knowledge of EduSys and academic tutoring.
 */
function buildSystemPrompt($role, $name) {
    $roleSpecificIntro = "";

    switch ($role) {
        case 'teacher':
            $roleSpecificIntro = "You are assisting a TEACHER named '{$name}'. Help them with:
- EduSys Teacher features: Creating live classes, scheduling lectures, managing student batches, uploading materials/assignments, grading student submissions, creating exams/MCQ tests, managing student doubts, tracking attendance, setting up offline tuition sessions, and viewing earnings.
- Teaching pedagogy: Formulating lesson plans, creating engaging quiz questions, explaining tough pedagogical topics, and offering classroom management advice.";
            break;

        case 'student':
            $roleSpecificIntro = "You are assisting a STUDENT named '{$name}'. Help them with:
- Subject doubts & homework: Math, Physics, Chemistry, Biology, Computer Science/Coding, English, and Social Sciences. Give clear step-by-step explanations, formulas, intuitive examples, and encouragement.
- EduSys Student features: Joining live classes (live_class_room.php), watching recorded classes (recorded_classes.php), submitting assignments, checking attendance percentage, taking online tests/exams, downloading notes/materials, asking teacher doubts, finding new tutors (tuition-finder.php), and tracking progress.";
            break;

        case 'parent':
            $roleSpecificIntro = "You are assisting a PARENT named '{$name}'. Help them with:
- Tracking their child's academic performance, live class attendance, assignment scores, and test results.
- Viewing fee payment statuses, scheduling PTMs (Parent-Teacher Meetings), communicating with teachers, and general child study guidance.";
            break;

        case 'admin':
            $roleSpecificIntro = "You are assisting an ADMINISTRATOR named '{$name}'. Help them with:
- System overview, managing teachers & students, batch allocation, salary & fee tracking, verifying teacher credentials, live class analytics, and portal settings.";
            break;

        default:
            $roleSpecificIntro = "You are assisting a VISITOR / GUEST on the EduSys platform. Help them explore:
- What EduSys offers: Online and offline tutoring, interactive live classrooms with screen sharing and auto-recording, tutor matchmaking (Tuition Finder), assignment & exam management, and how to register as a student, teacher, or parent.";
            break;
    }

    return <<<PROMPT
You are "EduBot", the intelligent, friendly, and highly capable AI Assistant integrated into EduSys — a comprehensive modern educational and tuition management platform.

CURRENT USER CONTEXT:
- Name: {$name}
- Role: {$role}

{$roleSpecificIntro}

WEBSITE ARCHITECTURE & NAVIGATION:
1. Live Classroom:
   - URL: live_class_room.php
   - Features: Real-time video/audio, screen sharing, in-class text chat, whiteboarding, teacher auto-recordings with quality controls (320p, 720p, 1080p).
   - Attendance is automatically marked when a student joins a live class.
2. Recorded Classes:
   - URL: recorded_classes.php (or from dashboard 'Recorded Classes' link)
   - Auto-saved to 'uploads/recordings/' with format {Class_Name}_{Date_Time}.webm. Students can replay lectures at any time.
3. Assignments & Materials:
   - Teachers upload lecture slides/PDFs in 'Materials' section.
   - Assignments: Teachers set deadlines and descriptions; students upload files or solutions; teachers provide grades and feedback.
4. Tests & Exams:
   - Interactive MCQ exams with automatic timer, instant scoring, and performance analytics.
5. Doubts Section:
   - Dedicated doubt-clearing forum where students post questions with descriptions or images, and teachers provide answers.
6. Tuition Finder:
   - Allows students to find verified tutors for either online or in-person home tutoring tailored to subject, class level, and location.

ACADEMIC & SUBJECT TUTORING INSTRUCTIONS:
- Whenever the user asks any educational or academic doubt (e.g., Mathematics, Physics, Chemistry, Biology, History, Computer Programming, Grammar, etc.):
  1. Provide clear, accurate, and step-by-step explanations.
  2. Use markdown formatting: bold key concepts, bullet lists for steps, and clear notation for formulas (e.g. F = m * a, E = mc^2).
  3. Offer a concise intuitive summary followed by the breakdown.
  4. Keep the tone encouraging, patient, and educational.

RESPONSE GUIDELINES:
- Be concise, welcoming, and directly helpful.
- When explaining site functionality, give specific directions (e.g., "Go to your Dashboard and click on 'Live Classes'").
- Format nicely with markdown (bullet points, bold text, code blocks where appropriate).
- Avoid robotic disclaimers. Always aim to solve their doubt or guide them to the right page in EduSys.
PROMPT;
}

/**
 * Sends chat request to Groq API with automatic fallback through configured models.
 */
function callGroqWithFallbacks($messages) {
    $apiKey = defined('GROQ_API_KEY') ? GROQ_API_KEY : '';
    if (empty($apiKey)) {
        return ['success' => false, 'msg' => 'Groq API key is not configured in config/ai.php.'];
    }

    // Models to attempt in order
    $modelsToTry = [];
    if (defined('GROQ_MODEL') && GROQ_MODEL) {
        $modelsToTry[] = GROQ_MODEL;
    }
    if (defined('GROQ_FALLBACK_MODELS') && is_array(GROQ_FALLBACK_MODELS)) {
        foreach (GROQ_FALLBACK_MODELS as $fm) {
            if (!in_array($fm, $modelsToTry)) {
                $modelsToTry[] = $fm;
            }
        }
    }
    // Default safe fallbacks
    if (!in_array('qwen/qwen3.8-27b', $modelsToTry)) {
        $modelsToTry[] = 'qwen/qwen3.8-27b';
    }
    if (!in_array('openai/gpt-oss-120b', $modelsToTry)) {
        $modelsToTry[] = 'openai/gpt-oss-120b';
    }

    $lastError = 'Unknown error';

    foreach ($modelsToTry as $model) {
        $result = sendGroqRequest($model, $messages, $apiKey);
        if ($result['success']) {
            return $result;
        }
        $lastError = $result['msg'] ?? 'Model failed';
    }

    return ['success' => false, 'msg' => 'All AI models were unavailable: ' . $lastError];
}

/**
 * Executes a single completion request to Groq API for a given model.
 */
function sendGroqRequest($model, $messages, $apiKey) {
    $url = 'https://api.groq.com/openai/v1/chat/completions';

    $payload = [
        'model' => $model,
        'messages' => $messages,
        'max_tokens' => 800,
        'temperature' => 0.7
    ];

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $apiKey
        ],
        CURLOPT_TIMEOUT => 25,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($curlError) {
        return ['success' => false, 'msg' => 'Network error: ' . $curlError];
    }

    $data = json_decode($response, true);

    if ($httpCode !== 200 || !isset($data['choices'][0]['message']['content'])) {
        $errMsg = $data['error']['message'] ?? "HTTP {$httpCode}";
        return ['success' => false, 'msg' => "Model {$model} returned error: {$errMsg}"];
    }

    $reply = trim($data['choices'][0]['message']['content']);
    if ($reply === '') {
        // In case model responded into reasoning instead
        $reply = trim($data['choices'][0]['message']['reasoning'] ?? 'I received your question. How can I assist you further?');
    }

    return [
        'success' => true,
        'reply' => $reply,
        'model' => $model
    ];
}
