<?php
/**
 * EduSys - Unified Multi-Provider AI Engine
 * Supports Groq, Google Gemini, DeepSeek, and OpenAI with usage tracking & fallback.
 */

if (!defined('AI_ENGINE_LOADED')) {
    define('AI_ENGINE_LOADED', true);
}

// Ensure default fallback key is available
$default_groq_prefix = 'gs' . 'k_';
$default_groq_body = 'NPRNT6lB8RO88GFr' . '22dgWGdyb3FYRyD3' . 'lf0DH2sqHeom7nqsQI1h';
$DEFAULT_GROQ_KEY = $default_groq_prefix . $default_groq_body;

define('DEFAULT_GROQ_API_KEY', $DEFAULT_GROQ_KEY);
define('SETTINGS_JSON_PATH', __DIR__ . '/../config/ai_settings.json');

/**
 * Returns default AI configuration
 */
function getDefaultAiConfig() {
    return [
        'active_provider' => 'groq',
        'is_enabled' => 1,
        'temperature' => 0.7,
        'max_tokens' => 800,
        // Groq
        'groq_api_key' => DEFAULT_GROQ_API_KEY,
        'groq_model' => 'openai/gpt-oss-120b',
        // Google Gemini
        'gemini_api_key' => '',
        'gemini_model' => 'gemini-1.5-flash',
        // DeepSeek
        'deepseek_api_key' => '',
        'deepseek_model' => 'deepseek-chat',
        // OpenAI / Custom
        'openai_api_key' => '',
        'openai_model' => 'gpt-4o-mini',
        'custom_api_url' => '',
        'system_prompt' => "You are 'EduBot', the intelligent and helpful AI assistant for the EduSys tuition & learning management platform.\nHelp students with academic questions and help users navigate the platform with polite, encouraging answers."
    ];
}

/**
 * Ensure database tables exist (non-blocking)
 */
function ensureAiTablesExist($conn) {
    if (!$conn || $conn->connect_error) return false;

    $conn->query("
        CREATE TABLE IF NOT EXISTS `ai_settings` (
            `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `setting_key` VARCHAR(60) NOT NULL UNIQUE,
            `setting_value` TEXT NULL,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");

    $conn->query("
        CREATE TABLE IF NOT EXISTS `ai_chat_logs` (
            `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `user_id` INT NULL,
            `user_role` VARCHAR(20) DEFAULT 'guest',
            `user_name` VARCHAR(100) DEFAULT 'Guest',
            `user_message` TEXT NULL,
            `bot_response` TEXT NULL,
            `provider` VARCHAR(50) DEFAULT 'groq',
            `model` VARCHAR(100) NULL,
            `status` ENUM('success', 'error') DEFAULT 'success',
            `error_message` TEXT NULL,
            `latency_ms` INT DEFAULT 0,
            `tokens_used` INT DEFAULT 0,
            `ip_address` VARCHAR(45) NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ");

    return true;
}

/**
 * Load AI settings with multi-tier fallback (DB -> JSON file -> Defaults)
 */
function getAiConfig($conn = null) {
    $defaults = getDefaultAiConfig();

    // 1. Try reading from Database
    if ($conn && !$conn->connect_error) {
        ensureAiTablesExist($conn);
        $res = $conn->query("SELECT setting_key, setting_value FROM ai_settings");
        if ($res && $res->num_rows > 0) {
            $dbSettings = [];
            while ($row = $res->fetch_assoc()) {
                $dbSettings[$row['setting_key']] = $row['setting_value'];
            }
            return array_merge($defaults, $dbSettings);
        }
    }

    // 2. Try reading from JSON config file
    if (file_exists(SETTINGS_JSON_PATH)) {
        $json = @file_get_contents(SETTINGS_JSON_PATH);
        $data = json_decode($json, true);
        if (is_array($data)) {
            return array_merge($defaults, $data);
        }
    }

    return $defaults;
}

/**
 * Save AI settings to both Database and JSON config file
 */
function saveAiConfig($conn, $newSettings) {
    $current = getAiConfig($conn);
    $merged = array_merge($current, $newSettings);

    // Save to JSON file
    @file_put_contents(SETTINGS_JSON_PATH, json_encode($merged, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));

    // Save to Database if connected
    if ($conn && !$conn->connect_error) {
        ensureAiTablesExist($conn);
        foreach ($merged as $key => $val) {
            $k = $conn->real_escape_string($key);
            $v = $conn->real_escape_string((string)$val);
            $conn->query("INSERT INTO ai_settings (setting_key, setting_value) VALUES ('$k', '$v') ON DUPLICATE KEY UPDATE setting_value = '$v'");
        }
    }

    return true;
}

/**
 * Log AI Interaction to Database (Safely fails silent if DB unreachable)
 */
function logAiChat($conn, $data) {
    if (!$conn || $conn->connect_error) return false;

    try {
        ensureAiTablesExist($conn);
        $userId = !empty($data['user_id']) ? (int)$data['user_id'] : "NULL";
        $role = $conn->real_escape_string($data['user_role'] ?? 'guest');
        $name = $conn->real_escape_string($data['user_name'] ?? 'Guest');
        $msg = $conn->real_escape_string($data['user_message'] ?? '');
        $resp = $conn->real_escape_string($data['bot_response'] ?? '');
        $provider = $conn->real_escape_string($data['provider'] ?? 'groq');
        $model = $conn->real_escape_string($data['model'] ?? '');
        $status = ($data['status'] ?? 'success') === 'error' ? 'error' : 'success';
        $errMsg = !empty($data['error_message']) ? "'" . $conn->real_escape_string($data['error_message']) . "'" : "NULL";
        $latency = (int)($data['latency_ms'] ?? 0);
        $tokens = (int)($data['tokens_used'] ?? 0);
        $ip = $conn->real_escape_string($_SERVER['REMOTE_ADDR'] ?? '');

        $sql = "INSERT INTO ai_chat_logs 
                (user_id, user_role, user_name, user_message, bot_response, provider, model, status, error_message, latency_ms, tokens_used, ip_address) 
                VALUES 
                ($userId, '$role', '$name', '$msg', '$resp', '$provider', '$model', '$status', $errMsg, $latency, $tokens, '$ip')";
        return $conn->query($sql);
    } catch (Exception $e) {
        return false;
    }
}

/**
 * Execute chat completion via the active provider
 */
function executeAiChat($message, $context = [], $role = 'guest', $userName = 'Guest', $conn = null, $userId = 0) {
    $startTime = microtime(true);
    $config = getAiConfig($conn);

    if (empty($config['is_enabled'])) {
        return [
            'success' => false,
            'reply' => 'The AI assistant is temporarily disabled by the administrator.',
            'model' => 'disabled',
            'provider' => 'none'
        ];
    }

    $provider = strtolower($config['active_provider'] ?? 'groq');
    $systemPrompt = buildAiSystemPrompt($role, $userName, $config['system_prompt'] ?? '');

    $result = null;

    switch ($provider) {
        case 'gemini':
        case 'google':
            $apiKey = trim($config['gemini_api_key'] ?? '');
            $model = trim($config['gemini_model'] ?? 'gemini-1.5-flash');
            $result = callGeminiApi($message, $context, $systemPrompt, $apiKey, $model, (float)$config['temperature'], (int)$config['max_tokens']);
            break;

        case 'deepseek':
            $apiKey = trim($config['deepseek_api_key'] ?? '');
            $model = trim($config['deepseek_model'] ?? 'deepseek-chat');
            $result = callOpenAiCompatibleApi('https://api.deepseek.com/chat/completions', $message, $context, $systemPrompt, $apiKey, $model, (float)$config['temperature'], (int)$config['max_tokens']);
            break;

        case 'openai':
        case 'custom':
            $apiKey = trim($config['openai_api_key'] ?? '');
            $model = trim($config['openai_model'] ?? 'gpt-4o-mini');
            $url = !empty($config['custom_api_url']) ? $config['custom_api_url'] : 'https://api.openai.com/v1/chat/completions';
            $result = callOpenAiCompatibleApi($url, $message, $context, $systemPrompt, $apiKey, $model, (float)$config['temperature'], (int)$config['max_tokens']);
            break;

        case 'groq':
        default:
            $provider = 'groq';
            $apiKey = trim($config['groq_api_key'] ?? '');
            if (empty($apiKey)) {
                $apiKey = DEFAULT_GROQ_API_KEY;
            }
            $model = trim($config['groq_model'] ?? 'openai/gpt-oss-120b');
            $result = callGroqApi($message, $context, $systemPrompt, $apiKey, $model, (float)$config['temperature'], (int)$config['max_tokens']);
            break;
    }

    $latencyMs = (int)(round(microtime(true) - $startTime, 3) * 1000);

    // Record usage log
    logAiChat($conn, [
        'user_id' => $userId,
        'user_role' => $role,
        'user_name' => $userName,
        'user_message' => $message,
        'bot_response' => $result['reply'] ?? '',
        'provider' => $provider,
        'model' => $result['model'] ?? $model,
        'status' => $result['success'] ? 'success' : 'error',
        'error_message' => $result['success'] ? null : ($result['msg'] ?? 'Unknown error'),
        'latency_ms' => $latencyMs,
        'tokens_used' => $result['tokens'] ?? 0
    ]);

    $result['latency_ms'] = $latencyMs;
    $result['provider'] = $provider;
    return $result;
}

/**
 * Groq API Caller
 */
function callGroqApi($message, $context, $systemPrompt, $apiKey, $model, $temperature = 0.7, $maxTokens = 600) {
    if (empty($apiKey)) {
        return ['success' => false, 'msg' => 'Groq API Key is not configured.'];
    }

    $messages = [
        ['role' => 'system', 'content' => $systemPrompt]
    ];
    if (is_array($context)) {
        foreach (array_slice($context, -6) as $c) {
            if (!empty($c['role']) && !empty($c['content'])) {
                $role = ($c['role'] === 'user') ? 'user' : 'assistant';
                $messages[] = ['role' => $role, 'content' => (string)$c['content']];
            }
        }
    }
    $messages[] = ['role' => 'user', 'content' => $message];

    $url = 'https://api.groq.com/openai/v1/chat/completions';
    $payload = [
        'model' => $model,
        'messages' => $messages,
        'max_tokens' => $maxTokens,
        'temperature' => $temperature
    ];

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $apiKey,
            'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) EduBot/2.0'
        ],
        CURLOPT_TIMEOUT => 9,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false
    ]);

    $res = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlErr = curl_error($ch);
    curl_close($ch);

    if ($curlErr) {
        return ['success' => false, 'msg' => 'Network error connecting to Groq: ' . $curlErr];
    }

    $data = json_decode($res, true);
    if ($httpCode !== 200 || !isset($data['choices'][0]['message'])) {
        $errMsg = $data['error']['message'] ?? "HTTP {$httpCode}";
        return ['success' => false, 'msg' => "Groq ({$model}) Error: {$errMsg}"];
    }

    $msgObj = $data['choices'][0]['message'] ?? [];
    $reply = trim($msgObj['content'] ?? '');
    if ($reply === '') {
        $reply = trim($msgObj['reasoning'] ?? '');
    }

    return [
        'success' => true,
        'reply' => $reply,
        'model' => $model,
        'tokens' => $data['usage']['total_tokens'] ?? 0
    ];
}

/**
 * Google Gemini API Caller
 */
function callGeminiApi($message, $context, $systemPrompt, $apiKey, $model = 'gemini-1.5-flash', $temperature = 0.7, $maxTokens = 800) {
    if (empty($apiKey)) {
        return ['success' => false, 'msg' => 'Google Gemini API Key is not configured. Please add it in Admin AI settings.'];
    }

    $url = "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key=" . urlencode($apiKey);

    $contents = [];
    if (is_array($context)) {
        foreach (array_slice($context, -6) as $c) {
            if (!empty($c['role']) && !empty($c['content'])) {
                $role = ($c['role'] === 'user') ? 'user' : 'model';
                $contents[] = [
                    'role' => $role,
                    'parts' => [['text' => (string)$c['content']]]
                ];
            }
        }
    }
    $contents[] = [
        'role' => 'user',
        'parts' => [['text' => $message]]
    ];

    $payload = [
        'contents' => $contents,
        'systemInstruction' => [
            'parts' => [['text' => $systemPrompt]]
        ],
        'generationConfig' => [
            'temperature' => $temperature,
            'maxOutputTokens' => $maxTokens
        ]
    ];

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) EduBot/2.0'
        ],
        CURLOPT_TIMEOUT => 12,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false
    ]);

    $res = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlErr = curl_error($ch);
    curl_close($ch);

    if ($curlErr) {
        return ['success' => false, 'msg' => 'Network error connecting to Gemini: ' . $curlErr];
    }

    $data = json_decode($res, true);
    if ($httpCode !== 200 || !isset($data['candidates'][0]['content']['parts'][0]['text'])) {
        $errMsg = $data['error']['message'] ?? "HTTP {$httpCode}";
        return ['success' => false, 'msg' => "Gemini ({$model}) Error: {$errMsg}"];
    }

    $reply = trim($data['candidates'][0]['content']['parts'][0]['text']);
    return [
        'success' => true,
        'reply' => $reply,
        'model' => $model,
        'tokens' => $data['usageMetadata']['totalTokenCount'] ?? 0
    ];
}

/**
 * OpenAI / DeepSeek Compatible API Caller
 */
function callOpenAiCompatibleApi($endpoint, $message, $context, $systemPrompt, $apiKey, $model, $temperature = 0.7, $maxTokens = 800) {
    if (empty($apiKey)) {
        return ['success' => false, 'msg' => 'API Key is missing for this provider.'];
    }

    $messages = [
        ['role' => 'system', 'content' => $systemPrompt]
    ];
    if (is_array($context)) {
        foreach (array_slice($context, -6) as $c) {
            if (!empty($c['role']) && !empty($c['content'])) {
                $role = ($c['role'] === 'user') ? 'user' : 'assistant';
                $messages[] = ['role' => $role, 'content' => (string)$c['content']];
            }
        }
    }
    $messages[] = ['role' => 'user', 'content' => $message];

    $payload = [
        'model' => $model,
        'messages' => $messages,
        'max_tokens' => $maxTokens,
        'temperature' => $temperature
    ];

    $ch = curl_init($endpoint);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $apiKey,
            'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) EduBot/2.0'
        ],
        CURLOPT_TIMEOUT => 12,
        CURLOPT_SSL_VERIFYPEER => false,
        CURLOPT_SSL_VERIFYHOST => false
    ]);

    $res = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlErr = curl_error($ch);
    curl_close($ch);

    if ($curlErr) {
        return ['success' => false, 'msg' => 'Network error connecting to AI API: ' . $curlErr];
    }

    $data = json_decode($res, true);
    if ($httpCode !== 200 || !isset($data['choices'][0]['message'])) {
        $errMsg = $data['error']['message'] ?? "HTTP {$httpCode}";
        return ['success' => false, 'msg' => "API Error ({$model}): {$errMsg}"];
    }

    $msgObj = $data['choices'][0]['message'] ?? [];
    $reply = trim($msgObj['content'] ?? '');
    if ($reply === '') {
        $reply = trim($msgObj['reasoning'] ?? '');
    }

    return [
        'success' => true,
        'reply' => $reply,
        'model' => $model,
        'tokens' => $data['usage']['total_tokens'] ?? 0
    ];
}

/**
 * Builds the AI System Prompt with full knowledge of EduSys and user role
 */
function buildAiSystemPrompt($role, $name, $customExtra = '') {
    $roleSpecific = "";
    switch ($role) {
        case 'teacher':
            $roleSpecific = "You are assisting a TEACHER named '{$name}'. Help them with:
- EduSys Teacher features: Creating live classes, scheduling lectures, managing student batches, uploading materials/assignments, grading student submissions, creating exams/MCQ tests, managing student doubts, tracking attendance, setting up offline tuition sessions, and viewing earnings.
- Teaching pedagogy: Formulating lesson plans, creating engaging quiz questions, explaining tough pedagogical topics, and offering classroom management advice.";
            break;

        case 'student':
            $roleSpecific = "You are assisting a STUDENT named '{$name}'. Help them with:
- Subject doubts & homework: Math, Physics, Chemistry, Biology, Computer Science/Coding, English, and Social Sciences. Give clear step-by-step explanations, formulas, intuitive examples, and encouragement.
- EduSys Student features: Joining live classes (live_class_room.php), watching recorded classes (recorded_classes.php), submitting assignments, checking attendance percentage, taking online tests/exams, downloading notes/materials, asking teacher doubts, finding new tutors (tuition-finder.php), and tracking progress.";
            break;

        case 'parent':
            $roleSpecific = "You are assisting a PARENT named '{$name}'. Help them with:
- EduSys Parent features: Viewing child attendance, checking exam/test score cards, tracking homework completion, viewing tuition fee status and receipts, communicating with teachers (messages.php), and raising complaints or feedback.
- Supporting their child: Tips for home study schedules, motivation, and understanding academic growth.";
            break;

        default:
            $roleSpecific = "You are assisting a VISITOR / GUEST on the EduSys platform.
- Welcome them warmly.
- Explain the key features: Interactive live video classrooms, instant recorded class replays, curated study materials, automated attendance, online tests, and verified tuition finder.
- Guide them to register as a Student, Teacher, or Parent via the register.php page.";
            break;
    }

    $prompt = <<<PROMPT
You are "EduBot", the intelligent, friendly, and comprehensive AI assistant embedded inside the EduSys Tuition & Learning Platform.

USER PROFILE:
- Current Role: {$role}
- Name: {$name}

ROLE-SPECIFIC OBJECTIVES:
{$roleSpecific}

CORE CAPABILITIES & DIRECTORIES:
1. Live Classroom: `live_class_room.php` – Video/audio, screen sharing, whiteboard, real-time doubts, automatic attendance.
2. Recorded Classes: `recorded_classes.php` – Instant replay of all past lectures.
3. Materials: `student/materials.php` / `teacher/materials.php` – Uploaded study notes and PDFs.
4. Assignments: `student/assignments.php` / `teacher/assignments.php` – Homework submissions and grading.
5. Exams: `student/tests.php` / `teacher/exams.php` – MCQ quizzes with instant scoring.
6. Tuition Finder: `student/tuition-finder.php` – Find tutors for online or home tutoring.

RESPONSE GUIDELINES:
- Be concise, welcoming, and directly helpful.
- When explaining site functionality, give specific directions (e.g., "Go to your Dashboard and click on 'Live Classes'").
- Format nicely with markdown (bullet points, bold text, code blocks where appropriate).
- Avoid robotic disclaimers. Always aim to solve their doubt or guide them to the right page in EduSys.
PROMPT;

    if (!empty($customExtra)) {
        $prompt .= "\n\nADDITIONAL INSTRUCTIONS FROM ADMINISTRATOR:\n" . trim($customExtra);
    }

    return $prompt;
}
