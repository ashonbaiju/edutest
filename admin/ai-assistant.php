<?php
require_once '../includes/header.php';
requireRole('admin');
require_once __DIR__ . '/../includes/ai_engine.php';

ensureAiTablesExist($conn);

$msg = '';

// Handle AJAX connection test
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'test_connection') {
    header('Content-Type: application/json');
    $provider = trim($_POST['provider'] ?? 'groq');
    $apiKey   = trim($_POST['api_key'] ?? '');
    $model    = trim($_POST['model'] ?? '');
    $customUrl = trim($_POST['custom_url'] ?? '');

    if ($provider === 'groq' && empty($apiKey)) {
        $apiKey = DEFAULT_GROQ_API_KEY;
    }

    $start = microtime(true);
    $res = null;

    if ($provider === 'gemini') {
        $res = callGeminiApi('Reply with exactly "Google Gemini Connected Successfully!"', [], 'You are a test agent. Keep answer short.', $apiKey, $model ?: 'gemini-1.5-flash', 0.2, 50);
    } elseif ($provider === 'deepseek') {
        $res = callOpenAiCompatibleApi('https://api.deepseek.com/chat/completions', 'Reply with exactly "DeepSeek Connected Successfully!"', [], 'You are a test agent. Keep answer short.', $apiKey, $model ?: 'deepseek-chat', 0.2, 50);
    } elseif ($provider === 'openai' || $provider === 'custom') {
        $url = $customUrl ?: 'https://api.openai.com/v1/chat/completions';
        $res = callOpenAiCompatibleApi($url, 'Reply with exactly "OpenAI Connected Successfully!"', [], 'You are a test agent. Keep answer short.', $apiKey, $model ?: 'gpt-4o-mini', 0.2, 50);
    } else {
        $res = callGroqApi('Reply with exactly "Groq AI Connected Successfully!"', [], 'You are a test agent. Keep answer short.', $apiKey, $model ?: 'openai/gpt-oss-120b', 0.2, 50);
    }

    $latency = (int)(round(microtime(true) - $start, 3) * 1000);
    $res['latency_ms'] = $latency;
    echo json_encode($res);
    exit;
}

// Handle Clear Logs
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'clear_logs') {
    $conn->query("TRUNCATE TABLE ai_chat_logs");
    $msg = '<div class="alert alert-success"><i class="fa-solid fa-check-circle"></i> AI chat history has been cleared successfully.</div>';
}

// Handle Save Settings
if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'save_settings') {
    $newConfig = [
        'active_provider' => trim($_POST['active_provider'] ?? 'groq'),
        'is_enabled'      => isset($_POST['is_enabled']) ? 1 : 0,
        'temperature'     => (float)($_POST['temperature'] ?? 0.7),
        'max_tokens'      => (int)($_POST['max_tokens'] ?? 800),
        'groq_api_key'    => trim($_POST['groq_api_key'] ?? ''),
        'groq_model'      => trim($_POST['groq_model'] ?? 'openai/gpt-oss-120b'),
        'gemini_api_key'  => trim($_POST['gemini_api_key'] ?? ''),
        'gemini_model'    => trim($_POST['gemini_model'] ?? 'gemini-1.5-flash'),
        'deepseek_api_key'=> trim($_POST['deepseek_api_key'] ?? ''),
        'deepseek_model'  => trim($_POST['deepseek_model'] ?? 'deepseek-chat'),
        'openai_api_key'  => trim($_POST['openai_api_key'] ?? ''),
        'openai_model'    => trim($_POST['openai_model'] ?? 'gpt-4o-mini'),
        'custom_api_url'  => trim($_POST['custom_api_url'] ?? ''),
        'system_prompt'   => trim($_POST['system_prompt'] ?? '')
    ];

    saveAiConfig($conn, $newConfig);
    $msg = '<div class="alert alert-success"><i class="fa-solid fa-check-circle"></i> AI settings & API configurations saved successfully!</div>';
}

// Load current configuration
$aiConfig = getAiConfig($conn);

// Fetch Usage Statistics
$totalQueries = 0;
$todayQueries = 0;
$avgLatency = 0;
$successCount = 0;

$statRes = $conn->query("
    SELECT 
        COUNT(*) as total,
        SUM(DATE(created_at) = CURDATE()) as today,
        AVG(CASE WHEN latency_ms > 0 THEN latency_ms ELSE NULL END) as avg_lat,
        SUM(status = 'success') as success_cnt
    FROM ai_chat_logs
");
if ($statRes && $row = $statRes->fetch_assoc()) {
    $totalQueries = (int)($row['total'] ?? 0);
    $todayQueries = (int)($row['today'] ?? 0);
    $avgLatency = (int)round($row['avg_lat'] ?? 0);
    $successCount = (int)($row['success_cnt'] ?? 0);
}
$successRate = $totalQueries > 0 ? round(($successCount / $totalQueries) * 100, 1) : 100;

// Fetch role breakdown
$roleStats = [
    'student' => 0,
    'teacher' => 0,
    'parent' => 0,
    'guest' => 0
];
$rRes = $conn->query("SELECT user_role, COUNT(*) as cnt FROM ai_chat_logs GROUP BY user_role");
if ($rRes) {
    while ($rRow = $rRes->fetch_assoc()) {
        $rk = strtolower($rRow['user_role']);
        if (isset($roleStats[$rk])) {
            $roleStats[$rk] = (int)$rRow['cnt'];
        }
    }
}

// Fetch filter and logs
$filterRole = trim($_GET['role'] ?? '');
$searchQuery = trim($_GET['q'] ?? '');

$whereClause = "WHERE 1=1";
if ($filterRole !== '') {
    $safeRole = $conn->real_escape_string($filterRole);
    $whereClause .= " AND user_role = '$safeRole'";
}
if ($searchQuery !== '') {
    $safeQ = $conn->real_escape_string($searchQuery);
    $whereClause .= " AND (user_message LIKE '%$safeQ%' OR bot_response LIKE '%$safeQ%' OR user_name LIKE '%$safeQ%')";
}

$logsRes = $conn->query("
    SELECT * FROM ai_chat_logs 
    $whereClause 
    ORDER BY id DESC 
    LIMIT 60
");
?>

<div class="page-header" style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:15px;">
    <div>
        <h1><i class="fa-solid fa-robot" style="color:var(--primary); margin-right:8px;"></i>AI Chatbot & APIs</h1>
        <p>Switch AI providers (Groq, Gemini, DeepSeek, OpenAI), manage API keys, and track AI queries</p>
    </div>
    <div style="display:flex; gap:10px;">
        <span class="badge <?= !empty($aiConfig['is_enabled']) ? 'badge-success' : 'badge-danger' ?>" style="font-size:0.9rem; padding:8px 14px;">
            <i class="fa-solid fa-circle" style="font-size:8px; margin-right:6px;"></i>
            <?= !empty($aiConfig['is_enabled']) ? 'AI Active: ' . strtoupper($aiConfig['active_provider']) : 'AI Disabled' ?>
        </span>
    </div>
</div>

<?= $msg ?>

<!-- Quick Tabs -->
<div style="display:flex; gap:10px; margin-bottom:25px; border-bottom:1px solid var(--border); padding-bottom:12px;">
    <button type="button" class="btn btn-primary" id="tabBtnAnalytics" onclick="switchAiTab('analytics')">
        <i class="fa-solid fa-chart-line"></i> Usage Tracking & Logs
    </button>
    <button type="button" class="btn btn-outline" id="tabBtnSettings" onclick="switchAiTab('settings')">
        <i class="fa-solid fa-sliders"></i> Provider & API Settings
    </button>
</div>

<!-- ========================================== -->
<!-- TAB 1: USAGE ANALYTICS & LOGS               -->
<!-- ========================================== -->
<div id="aiTabAnalytics">
    <!-- Metric Cards -->
    <div class="stats-grid" style="grid-template-columns: repeat(auto-fit, minmax(210px, 1fr)); margin-bottom:25px;">
        <div class="stat-card">
            <div class="stat-icon" style="background:rgba(99,102,241,0.12); color:#6366f1;"><i class="fa-solid fa-comments"></i></div>
            <div class="stat-info">
                <span class="stat-label">Total AI Queries</span>
                <span class="stat-value"><?= number_format($totalQueries) ?></span>
                <span class="stat-sub">Lifetime conversations</span>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background:rgba(16,185,129,0.12); color:#10b981;"><i class="fa-solid fa-calendar-day"></i></div>
            <div class="stat-info">
                <span class="stat-label">Queries Today</span>
                <span class="stat-value"><?= number_format($todayQueries) ?></span>
                <span class="stat-sub">Active platform users</span>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background:rgba(245,158,11,0.12); color:#f59e0b;"><i class="fa-solid fa-bolt"></i></div>
            <div class="stat-info">
                <span class="stat-label">Avg. Response Time</span>
                <span class="stat-value"><?= $avgLatency ? $avgLatency . ' ms' : 'Fast (~1.2s)' ?></span>
                <span class="stat-sub">Across all models</span>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background:rgba(14,165,233,0.12); color:#0ea5e9;"><i class="fa-solid fa-microchip"></i></div>
            <div class="stat-info">
                <span class="stat-label">Active Provider</span>
                <span class="stat-value" style="font-size:1.3rem; text-transform:uppercase;"><?= htmlspecialchars($aiConfig['active_provider']) ?></span>
                <span class="stat-sub"><?= htmlspecialchars(substr($aiConfig[$aiConfig['active_provider'] . '_model'] ?? 'default', 0, 22)) ?></span>
            </div>
        </div>
    </div>

    <!-- Usage by Role Card -->
    <div class="chart-card" style="margin-bottom:25px;">
        <div class="chart-title"><i class="fa-solid fa-users" style="color:var(--primary); margin-right:8px;"></i>AI Queries by User Role</div>
        <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:15px; margin-top:15px;">
            <div style="padding:15px; border-radius:10px; background:var(--surface); border:1px solid var(--border);">
                <div style="font-size:0.85rem; color:var(--text-secondary);"><i class="fa-solid fa-graduation-cap" style="color:#6366f1;"></i> Students</div>
                <div style="font-size:1.6rem; font-weight:700; margin-top:5px;"><?= number_format($roleStats['student']) ?></div>
                <div style="font-size:0.75rem; color:var(--text-muted);">Subject doubts & assignments</div>
            </div>
            <div style="padding:15px; border-radius:10px; background:var(--surface); border:1px solid var(--border);">
                <div style="font-size:0.85rem; color:var(--text-secondary);"><i class="fa-solid fa-chalkboard-user" style="color:#10b981;"></i> Teachers</div>
                <div style="font-size:1.6rem; font-weight:700; margin-top:5px;"><?= number_format($roleStats['teacher']) ?></div>
                <div style="font-size:0.75rem; color:var(--text-muted);">Lesson planning & exams</div>
            </div>
            <div style="padding:15px; border-radius:10px; background:var(--surface); border:1px solid var(--border);">
                <div style="font-size:0.85rem; color:var(--text-secondary);"><i class="fa-solid fa-user-group" style="color:#f59e0b;"></i> Parents</div>
                <div style="font-size:1.6rem; font-weight:700; margin-top:5px;"><?= number_format($roleStats['parent']) ?></div>
                <div style="font-size:0.75rem; color:var(--text-muted);">Attendance & score inquiries</div>
            </div>
            <div style="padding:15px; border-radius:10px; background:var(--surface); border:1px solid var(--border);">
                <div style="font-size:0.85rem; color:var(--text-secondary);"><i class="fa-solid fa-globe" style="color:#0ea5e9;"></i> Visitors / Guests</div>
                <div style="font-size:1.6rem; font-weight:700; margin-top:5px;"><?= number_format($roleStats['guest']) ?></div>
                <div style="font-size:0.75rem; color:var(--text-muted);">Tuition finder & sign-up help</div>
            </div>
        </div>
    </div>

    <!-- Live Query Logs Table -->
    <div class="chart-card">
        <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; margin-bottom:18px;">
            <div class="chart-title" style="margin-bottom:0;"><i class="fa-solid fa-clock-rotate-left" style="color:var(--primary); margin-right:8px;"></i>Live AI Query Logs</div>
            
            <!-- Filters -->
            <form method="GET" style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                <input type="text" name="q" value="<?= htmlspecialchars($searchQuery) ?>" placeholder="Search questions..." class="form-control" style="width:200px; padding:6px 12px; font-size:0.85rem;">
                <select name="role" class="form-control" style="width:130px; padding:6px 10px; font-size:0.85rem;" onchange="this.form.submit()">
                    <option value="">All Roles</option>
                    <option value="student" <?= $filterRole === 'student' ? 'selected' : '' ?>>Students</option>
                    <option value="teacher" <?= $filterRole === 'teacher' ? 'selected' : '' ?>>Teachers</option>
                    <option value="parent" <?= $filterRole === 'parent' ? 'selected' : '' ?>>Parents</option>
                    <option value="guest" <?= $filterRole === 'guest' ? 'selected' : '' ?>>Guests</option>
                </select>
                <button type="submit" class="btn btn-secondary btn-sm"><i class="fa-solid fa-filter"></i> Filter</button>
                <?php if ($filterRole || $searchQuery): ?>
                    <a href="ai-assistant.php" class="btn btn-outline btn-sm">Clear</a>
                <?php endif; ?>
            </form>

            <form method="POST" onsubmit="return confirm('Are you sure you want to clear all AI chat logs?');" style="margin-left:auto;">
                <input type="hidden" name="action" value="clear_logs">
                <button type="submit" class="btn btn-danger btn-sm"><i class="fa-solid fa-trash"></i> Clear Logs</button>
            </form>
        </div>

        <div class="table-responsive">
            <table class="table" style="font-size:0.88rem;">
                <thead>
                    <tr>
                        <th>Time</th>
                        <th>User</th>
                        <th>Role</th>
                        <th>Question / Prompt</th>
                        <th>AI Response Preview</th>
                        <th>Provider / Model</th>
                        <th>Latency</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if ($logsRes && $logsRes->num_rows > 0): ?>
                        <?php while ($log = $logsRes->fetch_assoc()): ?>
                            <tr>
                                <td style="white-space:nowrap; color:var(--text-secondary); font-size:0.8rem;">
                                    <?= date('M d, h:i A', strtotime($log['created_at'])) ?>
                                </td>
                                <td style="font-weight:600;">
                                    <?= htmlspecialchars($log['user_name'] ?: 'Guest') ?>
                                </td>
                                <td>
                                    <?php
                                    $roleBadge = 'badge-secondary';
                                    if ($log['user_role'] === 'student') $roleBadge = 'badge-primary';
                                    elseif ($log['user_role'] === 'teacher') $roleBadge = 'badge-success';
                                    elseif ($log['user_role'] === 'parent') $roleBadge = 'badge-warning';
                                    ?>
                                    <span class="badge <?= $roleBadge ?>" style="font-size:0.75rem; text-transform:capitalize;">
                                        <?= htmlspecialchars($log['user_role']) ?>
                                    </span>
                                </td>
                                <td style="max-width:240px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap;" title="<?= htmlspecialchars($log['user_message']) ?>">
                                    <strong><?= htmlspecialchars(mb_substr($log['user_message'], 0, 70)) ?><?= mb_strlen($log['user_message']) > 70 ? '...' : '' ?></strong>
                                </td>
                                <td style="max-width:280px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; color:var(--text-secondary);" title="<?= htmlspecialchars($log['bot_response']) ?>">
                                    <?= htmlspecialchars(mb_substr(strip_tags($log['bot_response']), 0, 80)) ?><?= mb_strlen($log['bot_response']) > 80 ? '...' : '' ?>
                                </td>
                                <td>
                                    <span class="badge badge-info" style="font-size:0.72rem; text-transform:uppercase;">
                                        <?= htmlspecialchars($log['provider']) ?>
                                    </span>
                                    <span style="font-size:0.75rem; color:var(--text-muted); display:block;">
                                        <?= htmlspecialchars(substr($log['model'] ?? '', 0, 20)) ?>
                                    </span>
                                </td>
                                <td style="font-family:monospace; font-size:0.8rem; color:var(--text-secondary);">
                                    <?= $log['latency_ms'] ?>ms
                                </td>
                                <td>
                                    <?php if ($log['status'] === 'success'): ?>
                                        <span class="badge badge-success" style="font-size:0.72rem;"><i class="fa-solid fa-check"></i> OK</span>
                                    <?php else: ?>
                                        <span class="badge badge-danger" style="font-size:0.72rem;" title="<?= htmlspecialchars($log['error_message'] ?? '') ?>"><i class="fa-solid fa-xmark"></i> Err</span>
                                    <?php endif; ?>
                                </td>
                            </tr>
                        <?php endwhile; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="8" style="text-align:center; padding:40px; color:var(--text-muted);">
                                <i class="fa-solid fa-inbox" style="font-size:2rem; margin-bottom:10px; display:block;"></i>
                                No AI queries recorded yet. Questions asked through the EduBot chat widget will appear here live!
                            </td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- ========================================== -->
<!-- TAB 2: PROVIDER & API SETTINGS              -->
<!-- ========================================== -->
<div id="aiTabSettings" style="display:none;">
    <form method="POST">
        <input type="hidden" name="action" value="save_settings">

        <div class="charts-grid" style="grid-template-columns: 2fr 1fr; gap:25px;">
            <!-- Main Settings Column -->
            <div>
                <!-- Provider Selector Cards -->
                <div class="form-card" style="margin-bottom:25px;">
                    <div style="font-weight:700; font-size:1.1rem; margin-bottom:15px; display:flex; align-items:center; gap:8px;">
                        <i class="fa-solid fa-network-wired" style="color:var(--primary);"></i>
                        Choose Active AI Provider
                    </div>
                    <p style="font-size:0.85rem; color:var(--text-secondary); margin-bottom:20px;">
                        Select which artificial intelligence model powers the student, teacher, and guest chatbot. You can switch providers at any time.
                    </p>

                    <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(200px, 1fr)); gap:15px; margin-bottom:20px;">
                        <!-- Groq AI -->
                        <label class="provider-radio-card" style="border:2px solid <?= ($aiConfig['active_provider'] === 'groq') ? 'var(--primary)' : 'var(--border)' ?>; padding:15px; border-radius:12px; cursor:pointer; display:block; background:var(--surface);">
                            <input type="radio" name="active_provider" value="groq" <?= ($aiConfig['active_provider'] === 'groq') ? 'checked' : '' ?> onchange="highlightProvider(this.value)" style="margin-right:8px;">
                            <strong style="font-size:1rem;">⚡ Groq AI</strong>
                            <div style="font-size:0.78rem; color:var(--text-secondary); margin-top:5px;">
                                Ultra-fast (~1.2s), Llama 3.3, Qwen 27B & GPT-OSS 120B. Generous free tier.
                            </div>
                        </label>

                        <!-- Google Gemini -->
                        <label class="provider-radio-card" style="border:2px solid <?= ($aiConfig['active_provider'] === 'gemini') ? 'var(--primary)' : 'var(--border)' ?>; padding:15px; border-radius:12px; cursor:pointer; display:block; background:var(--surface);">
                            <input type="radio" name="active_provider" value="gemini" <?= ($aiConfig['active_provider'] === 'gemini') ? 'checked' : '' ?> onchange="highlightProvider(this.value)" style="margin-right:8px;">
                            <strong style="font-size:1rem;">✨ Google Gemini</strong>
                            <div style="font-size:0.78rem; color:var(--text-secondary); margin-top:5px;">
                                Gemini 1.5 Flash, 1.5 Pro & 2.0 Flash. High accuracy and comprehensive answers.
                            </div>
                        </label>

                        <!-- DeepSeek -->
                        <label class="provider-radio-card" style="border:2px solid <?= ($aiConfig['active_provider'] === 'deepseek') ? 'var(--primary)' : 'var(--border)' ?>; padding:15px; border-radius:12px; cursor:pointer; display:block; background:var(--surface);">
                            <input type="radio" name="active_provider" value="deepseek" <?= ($aiConfig['active_provider'] === 'deepseek') ? 'checked' : '' ?> onchange="highlightProvider(this.value)" style="margin-right:8px;">
                            <strong style="font-size:1rem;">🐋 DeepSeek</strong>
                            <div style="font-size:0.78rem; color:var(--text-secondary); margin-top:5px;">
                                DeepSeek-V3 & DeepSeek-R1. Strong in coding, mathematics, and reasoning.
                            </div>
                        </label>

                        <!-- OpenAI / Custom -->
                        <label class="provider-radio-card" style="border:2px solid <?= ($aiConfig['active_provider'] === 'openai') ? 'var(--primary)' : 'var(--border)' ?>; padding:15px; border-radius:12px; cursor:pointer; display:block; background:var(--surface);">
                            <input type="radio" name="active_provider" value="openai" <?= ($aiConfig['active_provider'] === 'openai') ? 'checked' : '' ?> onchange="highlightProvider(this.value)" style="margin-right:8px;">
                            <strong style="font-size:1rem;">🟢 OpenAI / Custom</strong>
                            <div style="font-size:0.78rem; color:var(--text-secondary); margin-top:5px;">
                                GPT-4o-mini, GPT-4o, or any OpenAI-compatible API proxy.
                            </div>
                        </label>
                    </div>
                </div>

                <!-- Provider Credentials & Models -->
                <div class="form-card" style="margin-bottom:25px;">
                    <div style="font-weight:700; font-size:1.1rem; margin-bottom:15px; display:flex; align-items:center; gap:8px;">
                        <i class="fa-solid fa-key" style="color:var(--primary);"></i>
                        API Keys & Model Configuration
                    </div>

                    <!-- 1. GROQ SETTINGS -->
                    <div class="provider-settings-panel" id="panel_groq" style="background:var(--surface); padding:20px; border-radius:12px; border:1px solid var(--border); margin-bottom:20px;">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
                            <h4 style="margin:0;"><i class="fa-solid fa-bolt" style="color:#f59e0b; margin-right:6px;"></i>Groq AI Configuration</h4>
                            <button type="button" class="btn btn-secondary btn-sm" onclick="testConnection('groq')">
                                <i class="fa-solid fa-plug"></i> Test Groq Connection
                            </button>
                        </div>
                        <div class="form-group" style="margin-bottom:12px;">
                            <label>Groq API Key</label>
                            <div class="password-wrap">
                                <input type="password" id="groq_api_key" name="groq_api_key" class="form-control" value="<?= htmlspecialchars($aiConfig['groq_api_key'] ?? '') ?>" placeholder="gsk_... (leave empty to use default built-in key)">
                                <button type="button" class="toggle-pass" onclick="togglePassField('groq_api_key')"><i class="fa-regular fa-eye"></i></button>
                            </div>
                            <small style="color:var(--text-muted);">Get a free key from <a href="https://console.groq.com/keys" target="_blank">console.groq.com</a></small>
                        </div>
                        <div class="form-group">
                            <label>Groq Model</label>
                            <select id="groq_model" name="groq_model" class="form-control">
                                <option value="openai/gpt-oss-120b" <?= ($aiConfig['groq_model'] === 'openai/gpt-oss-120b') ? 'selected' : '' ?>>openai/gpt-oss-120b (Recommended - Smart 120B reasoning)</option>
                                <option value="qwen/qwen3.8-27b" <?= ($aiConfig['groq_model'] === 'qwen/qwen3.8-27b') ? 'selected' : '' ?>>qwen/qwen3.8-27b (Super fast ~1.5s, Math & Code)</option>
                                <option value="openai/gpt-oss-20b" <?= ($aiConfig['groq_model'] === 'openai/gpt-oss-20b') ? 'selected' : '' ?>>openai/gpt-oss-20b (Balanced 20B)</option>
                            </select>
                        </div>
                    </div>

                    <!-- 2. GEMINI SETTINGS -->
                    <div class="provider-settings-panel" id="panel_gemini" style="background:var(--surface); padding:20px; border-radius:12px; border:1px solid var(--border); margin-bottom:20px;">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
                            <h4 style="margin:0;"><i class="fa-brands fa-google" style="color:#0ea5e9; margin-right:6px;"></i>Google Gemini Configuration</h4>
                            <button type="button" class="btn btn-secondary btn-sm" onclick="testConnection('gemini')">
                                <i class="fa-solid fa-plug"></i> Test Gemini Connection
                            </button>
                        </div>
                        <div class="form-group" style="margin-bottom:12px;">
                            <label>Google Gemini API Key</label>
                            <div class="password-wrap">
                                <input type="password" id="gemini_api_key" name="gemini_api_key" class="form-control" value="<?= htmlspecialchars($aiConfig['gemini_api_key'] ?? '') ?>" placeholder="AIzaSy...">
                                <button type="button" class="toggle-pass" onclick="togglePassField('gemini_api_key')"><i class="fa-regular fa-eye"></i></button>
                            </div>
                            <small style="color:var(--text-muted);">Get a free key from <a href="https://aistudio.google.com/app/apikey" target="_blank">Google AI Studio</a></small>
                        </div>
                        <div class="form-group">
                            <label>Gemini Model</label>
                            <select id="gemini_model" name="gemini_model" class="form-control">
                                <option value="gemini-1.5-flash" <?= ($aiConfig['gemini_model'] === 'gemini-1.5-flash') ? 'selected' : '' ?>>gemini-1.5-flash (Fast, free tier, recommended)</option>
                                <option value="gemini-1.5-pro" <?= ($aiConfig['gemini_model'] === 'gemini-1.5-pro') ? 'selected' : '' ?>>gemini-1.5-pro (Complex reasoning)</option>
                                <option value="gemini-2.0-flash" <?= ($aiConfig['gemini_model'] === 'gemini-2.0-flash') ? 'selected' : '' ?>>gemini-2.0-flash (Latest next-gen)</option>
                            </select>
                        </div>
                    </div>

                    <!-- 3. DEEPSEEK SETTINGS -->
                    <div class="provider-settings-panel" id="panel_deepseek" style="background:var(--surface); padding:20px; border-radius:12px; border:1px solid var(--border); margin-bottom:20px;">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
                            <h4 style="margin:0;"><i class="fa-solid fa-brain" style="color:#6366f1; margin-right:6px;"></i>DeepSeek AI Configuration</h4>
                            <button type="button" class="btn btn-secondary btn-sm" onclick="testConnection('deepseek')">
                                <i class="fa-solid fa-plug"></i> Test DeepSeek Connection
                            </button>
                        </div>
                        <div class="form-group" style="margin-bottom:12px;">
                            <label>DeepSeek API Key</label>
                            <div class="password-wrap">
                                <input type="password" id="deepseek_api_key" name="deepseek_api_key" class="form-control" value="<?= htmlspecialchars($aiConfig['deepseek_api_key'] ?? '') ?>" placeholder="sk-...">
                                <button type="button" class="toggle-pass" onclick="togglePassField('deepseek_api_key')"><i class="fa-regular fa-eye"></i></button>
                            </div>
                            <small style="color:var(--text-muted);">Get an API key from <a href="https://platform.deepseek.com/" target="_blank">platform.deepseek.com</a></small>
                        </div>
                        <div class="form-group">
                            <label>DeepSeek Model</label>
                            <select id="deepseek_model" name="deepseek_model" class="form-control">
                                <option value="deepseek-chat" <?= ($aiConfig['deepseek_model'] === 'deepseek-chat') ? 'selected' : '' ?>>deepseek-chat (DeepSeek V3)</option>
                                <option value="deepseek-reasoner" <?= ($aiConfig['deepseek_model'] === 'deepseek-reasoner') ? 'selected' : '' ?>>deepseek-reasoner (DeepSeek R1 reasoning)</option>
                            </select>
                        </div>
                    </div>

                    <!-- 4. OPENAI / CUSTOM SETTINGS -->
                    <div class="provider-settings-panel" id="panel_openai" style="background:var(--surface); padding:20px; border-radius:12px; border:1px solid var(--border);">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
                            <h4 style="margin:0;"><i class="fa-solid fa-cube" style="color:#10b981; margin-right:6px;"></i>OpenAI / Custom Endpoint</h4>
                            <button type="button" class="btn btn-secondary btn-sm" onclick="testConnection('openai')">
                                <i class="fa-solid fa-plug"></i> Test OpenAI Connection
                            </button>
                        </div>
                        <div class="form-group" style="margin-bottom:12px;">
                            <label>API Key</label>
                            <div class="password-wrap">
                                <input type="password" id="openai_api_key" name="openai_api_key" class="form-control" value="<?= htmlspecialchars($aiConfig['openai_api_key'] ?? '') ?>" placeholder="sk-...">
                                <button type="button" class="toggle-pass" onclick="togglePassField('openai_api_key')"><i class="fa-regular fa-eye"></i></button>
                            </div>
                        </div>
                        <div class="form-group" style="margin-bottom:12px;">
                            <label>Model Name</label>
                            <input type="text" id="openai_model" name="openai_model" class="form-control" value="<?= htmlspecialchars($aiConfig['openai_model'] ?? 'gpt-4o-mini') ?>" placeholder="gpt-4o-mini, gpt-4o...">
                        </div>
                        <div class="form-group">
                            <label>Custom Endpoint URL (Optional)</label>
                            <input type="url" id="custom_api_url" name="custom_api_url" class="form-control" value="<?= htmlspecialchars($aiConfig['custom_api_url'] ?? '') ?>" placeholder="https://api.openai.com/v1/chat/completions">
                            <small style="color:var(--text-muted);">Leave empty to use official OpenAI. Works with OpenRouter, Together AI, or local Ollama.</small>
                        </div>
                    </div>
                </div>

                <!-- Test Result Alert Banner (Hidden by default) -->
                <div id="testResultBox" style="display:none; padding:15px; border-radius:10px; margin-bottom:20px;"></div>

                <!-- System Prompt Customization -->
                <div class="form-card" style="margin-bottom:25px;">
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
                        <div style="font-weight:700; font-size:1.1rem; display:flex; align-items:center; gap:8px;">
                            <i class="fa-solid fa-comment-dots" style="color:var(--primary);"></i>
                            System Persona & Additional Instructions
                        </div>
                        <button type="button" class="btn btn-outline btn-sm" onclick="resetPrompt()">
                            <i class="fa-solid fa-rotate-left"></i> Reset to Default
                        </button>
                    </div>
                    <p style="font-size:0.85rem; color:var(--text-secondary); margin-bottom:15px;">
                        These instructions guide the AI on tone, institution policies, and platform assistance.
                    </p>
                    <textarea id="system_prompt" name="system_prompt" rows="5" class="form-control" style="font-size:0.88rem; font-family:monospace;"><?= htmlspecialchars($aiConfig['system_prompt'] ?? '') ?></textarea>
                </div>
            </div>

            <!-- Parameters & Actions Column -->
            <div>
                <div class="form-card" style="position:sticky; top:85px;">
                    <div style="font-weight:700; font-size:1.1rem; margin-bottom:15px;">
                        <i class="fa-solid fa-sliders" style="color:var(--primary); margin-right:6px;"></i>Controls
                    </div>

                    <div class="form-group" style="margin-bottom:20px;">
                        <label style="display:flex; align-items:center; gap:10px; cursor:pointer;">
                            <input type="checkbox" name="is_enabled" value="1" <?= !empty($aiConfig['is_enabled']) ? 'checked' : '' ?> style="width:18px; height:18px;">
                            <span style="font-weight:600;">Enable AI Assistant</span>
                        </label>
                        <small style="color:var(--text-muted); display:block; margin-top:4px;">When checked, the chatbot widget appears across all student, teacher, and guest pages.</small>
                    </div>

                    <div class="form-group" style="margin-bottom:20px;">
                        <label>Creativity / Temperature (<span id="tempVal"><?= $aiConfig['temperature'] ?></span>)</label>
                        <input type="range" name="temperature" min="0.0" max="1.0" step="0.1" value="<?= $aiConfig['temperature'] ?>" class="form-control" oninput="document.getElementById('tempVal').innerText = this.value" style="padding:0;">
                        <small style="color:var(--text-muted); display:flex; justify-content:space-between; margin-top:4px;">
                            <span>Precise (0.2)</span>
                            <span>Balanced (0.7)</span>
                            <span>Creative (1.0)</span>
                        </small>
                    </div>

                    <div class="form-group" style="margin-bottom:25px;">
                        <label>Max Response Length (Tokens)</label>
                        <input type="number" name="max_tokens" value="<?= (int)($aiConfig['max_tokens'] ?? 800) ?>" min="150" max="2500" step="50" class="form-control">
                        <small style="color:var(--text-muted);">~800 tokens is approximately 600 words.</small>
                    </div>

                    <button type="submit" class="btn btn-primary" style="width:100%; padding:12px; font-weight:700; font-size:1rem;">
                        <i class="fa-solid fa-floppy-disk"></i> Save Settings
                    </button>
                </div>
            </div>
        </div>
    </form>
</div>

<script>
function switchAiTab(tab) {
    const tabAnalytics = document.getElementById('aiTabAnalytics');
    const tabSettings  = document.getElementById('aiTabSettings');
    const btnAnalytics = document.getElementById('tabBtnAnalytics');
    const btnSettings  = document.getElementById('tabBtnSettings');

    if (tab === 'settings') {
        tabAnalytics.style.display = 'none';
        tabSettings.style.display  = 'block';
        btnSettings.className = 'btn btn-primary';
        btnAnalytics.className = 'btn btn-outline';
    } else {
        tabSettings.style.display  = 'none';
        tabAnalytics.style.display = 'block';
        btnAnalytics.className = 'btn btn-primary';
        btnSettings.className = 'btn btn-outline';
    }
}

function togglePassField(id) {
    const el = document.getElementById(id);
    if (!el) return;
    el.type = (el.type === 'password') ? 'text' : 'password';
}

function highlightProvider(prov) {
    document.querySelectorAll('.provider-radio-card').forEach(card => {
        card.style.borderColor = 'var(--border)';
    });
    const checkedRadio = document.querySelector('input[name="active_provider"]:checked');
    if (checkedRadio && checkedRadio.closest('.provider-radio-card')) {
        checkedRadio.closest('.provider-radio-card').style.borderColor = 'var(--primary)';
    }
}

async function testConnection(provider) {
    const box = document.getElementById('testResultBox');
    box.style.display = 'block';
    box.style.background = 'rgba(99,102,241,0.08)';
    box.style.border = '1px solid #6366f1';
    box.style.color = 'var(--text-primary)';
    box.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Pinging ' + provider.toUpperCase() + ' API... Please wait...';

    let apiKey = '';
    let model  = '';
    let customUrl = '';

    if (provider === 'gemini') {
        apiKey = document.getElementById('gemini_api_key').value;
        model  = document.getElementById('gemini_model').value;
    } else if (provider === 'deepseek') {
        apiKey = document.getElementById('deepseek_api_key').value;
        model  = document.getElementById('deepseek_model').value;
    } else if (provider === 'openai') {
        apiKey = document.getElementById('openai_api_key').value;
        model  = document.getElementById('openai_model').value;
        customUrl = document.getElementById('custom_api_url').value;
    } else {
        apiKey = document.getElementById('groq_api_key').value;
        model  = document.getElementById('groq_model').value;
    }

    const formData = new URLSearchParams();
    formData.append('action', 'test_connection');
    formData.append('provider', provider);
    formData.append('api_key', apiKey);
    formData.append('model', model);
    formData.append('custom_url', customUrl);

    try {
        const res = await fetch('ai-assistant.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: formData.toString()
        });

        const data = await res.json();
        if (data && data.success) {
            box.style.background = 'rgba(16,185,129,0.12)';
            box.style.border = '1px solid #10b981';
            box.style.color = '#065f46';
            box.innerHTML = `<strong><i class="fa-solid fa-circle-check"></i> Connection Successful!</strong><br>` +
                            `<span style="font-size:0.85rem;">Latency: <b>${data.latency_ms} ms</b> | Model: <b>${data.model}</b></span><br>` +
                            `<div style="margin-top:6px; font-style:italic; font-size:0.85rem;">"${data.reply}"</div>`;
        } else {
            box.style.background = 'rgba(239,68,68,0.12)';
            box.style.border = '1px solid #ef4444';
            box.style.color = '#991b1b';
            box.innerHTML = `<strong><i class="fa-solid fa-triangle-exclamation"></i> Connection Failed:</strong><br>` +
                            `<span style="font-size:0.85rem;">${data.msg || 'Unable to connect to ' + provider}</span>`;
        }
    } catch (e) {
        box.style.background = 'rgba(239,68,68,0.12)';
        box.style.border = '1px solid #ef4444';
        box.style.color = '#991b1b';
        box.innerHTML = `<strong><i class="fa-solid fa-triangle-exclamation"></i> Network Error:</strong> ${e.message}`;
    }
}

function resetPrompt() {
    document.getElementById('system_prompt').value = 
        "You are 'EduBot', the intelligent and helpful AI assistant for the EduSys tuition & learning management platform.\nHelp students with academic questions and help users navigate the platform with polite, encouraging answers.";
}
</script>

<?php require_once '../includes/footer.php'; ?>
