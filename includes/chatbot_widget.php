<?php
/**
 * EduBot AI Assistant Widget - EduSys
 * Interactive floating AI chatbot widget powered by Groq
 */

if (!defined('BASE_URL')) {
    require_once __DIR__ . '/../config/db.php';
}

$widgetBaseUrl = defined('BASE_URL') ? BASE_URL : '/edu/project/';
$currentRole = $_SESSION['role'] ?? 'guest';
$currentUserName = $_SESSION['name'] ?? 'Guest';

// Quick suggestions tailored to role
$suggestions = [];
if ($currentRole === 'teacher') {
    $suggestions = [
        "How do I start a live class?",
        "How to grade assignments?",
        "Suggest a quick 5-question math quiz",
        "How are class recordings saved?"
    ];
} elseif ($currentRole === 'student') {
    $suggestions = [
        "Explain Newton's Second Law with formula",
        "How do I join my live class?",
        "Where can I find recorded classes?",
        "How to submit my assignment?"
    ];
} elseif ($currentRole === 'parent') {
    $suggestions = [
        "How to check child's attendance?",
        "Where can I view exam results?",
        "How do I schedule a PTM?",
        "How to view fee status?"
    ];
} else {
    $suggestions = [
        "What is EduSys and how does it work?",
        "How to find a private tutor?",
        "How do live classes work?",
        "Explain photosynthesis in simple terms"
    ];
}

$suggestionsAttr = htmlspecialchars(json_encode($suggestions), ENT_QUOTES, 'UTF-8');
$apiAttr = htmlspecialchars($widgetBaseUrl . 'php/chatbot_api.php', ENT_QUOTES, 'UTF-8');
$currentNameEscaped = htmlspecialchars($currentUserName, ENT_QUOTES, 'UTF-8');

$chatbotWidget = <<<HTML
<!-- EduBot AI Assistant Floating Widget -->
<style>
:root {
    --edubot-primary: #6366f1;
    --edubot-primary-hover: #4f46e5;
    --edubot-secondary: #8b5cf6;
    --edubot-accent: #06b6d4;
    --edubot-bg: #ffffff;
    --edubot-surface: #f8fafc;
    --edubot-border: #e2e8f0;
    --edubot-text: #1e293b;
    --edubot-text-muted: #64748b;
    --edubot-bot-bubble: #f1f5f9;
    --edubot-bot-text: #1e293b;
    --edubot-user-bubble: linear-gradient(135deg, #6366f1, #8b5cf6);
    --edubot-shadow: 0 20px 45px -10px rgba(99, 102, 241, 0.25), 0 10px 20px -5px rgba(0, 0, 0, 0.08);
}

[data-theme="dark"] {
    --edubot-bg: #0f172a;
    --edubot-surface: #1e293b;
    --edubot-border: #334155;
    --edubot-text: #f1f5f9;
    --edubot-text-muted: #94a3b8;
    --edubot-bot-bubble: #1e293b;
    --edubot-bot-text: #f1f5f9;
    --edubot-shadow: 0 20px 45px -10px rgba(0, 0, 0, 0.6);
}

/* Floating Launcher Button */
.edubot-launcher {
    position: fixed;
    bottom: 24px;
    right: 24px;
    width: 60px;
    height: 60px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--edubot-primary), var(--edubot-secondary));
    border: none;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #ffffff;
    box-shadow: 0 10px 25px rgba(99, 102, 241, 0.45);
    z-index: 999999;
    transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
    outline: none;
}

.edubot-launcher:hover {
    transform: scale(1.08) translateY(-2px);
    box-shadow: 0 16px 32px rgba(99, 102, 241, 0.55);
}

.edubot-launcher:active {
    transform: scale(0.95);
}

.edubot-launcher-icon,
.edubot-launcher-close {
    position: absolute;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1), opacity 0.2s ease;
}

.edubot-launcher-icon {
    opacity: 1;
    transform: rotate(0deg) scale(1);
}

.edubot-launcher-close {
    opacity: 0;
    transform: rotate(-90deg) scale(0.5);
}

.edubot-launcher.is-active .edubot-launcher-icon {
    opacity: 0;
    transform: rotate(90deg) scale(0.5);
}

.edubot-launcher.is-active .edubot-launcher-close {
    opacity: 1;
    transform: rotate(0deg) scale(1);
}

.edubot-launcher-pulse {
    position: absolute;
    inset: -4px;
    border-radius: 50%;
    background: radial-gradient(circle, rgba(99, 102, 241, 0.4) 0%, rgba(99, 102, 241, 0) 70%);
    animation: edubotPulse 3s infinite ease-out;
    pointer-events: none;
    z-index: -1;
}

@keyframes edubotPulse {
    0% { transform: scale(0.95); opacity: 0.8; }
    50% { transform: scale(1.25); opacity: 0; }
    100% { transform: scale(1.25); opacity: 0; }
}

.edubot-launcher-tooltip {
    position: absolute;
    right: 72px;
    background: #1e293b;
    color: #ffffff;
    padding: 6px 12px;
    border-radius: 20px;
    font-size: 0.8rem;
    font-weight: 500;
    white-space: nowrap;
    opacity: 0;
    transform: translateX(10px);
    pointer-events: none;
    transition: all 0.25s ease;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    font-family: inherit;
}

.edubot-launcher:hover .edubot-launcher-tooltip {
    opacity: 1;
    transform: translateX(0);
}

/* Chatbot Popup Window */
.edubot-container {
    position: fixed;
    bottom: 96px;
    right: 24px;
    width: 390px;
    max-width: calc(100vw - 32px);
    height: 580px;
    max-height: calc(100vh - 120px);
    background: var(--edubot-bg);
    border-radius: 20px;
    border: 1px solid var(--edubot-border);
    box-shadow: var(--edubot-shadow);
    display: flex;
    flex-direction: column;
    overflow: hidden;
    z-index: 999998;
    transform: translateY(24px) scale(0.92);
    opacity: 0;
    visibility: hidden;
    pointer-events: none;
    transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.25s ease, visibility 0.25s;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Outfit", sans-serif;
}

.edubot-container.is-open {
    transform: translateY(0) scale(1);
    opacity: 1;
    visibility: visible;
    pointer-events: auto;
}

/* Header */
.edubot-header {
    background: linear-gradient(135deg, var(--edubot-primary), var(--edubot-secondary));
    color: #ffffff;
    padding: 14px 18px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
}

.edubot-header-profile {
    display: flex;
    align-items: center;
    gap: 10px;
}

.edubot-avatar-wrap {
    position: relative;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.2);
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.3);
}

.edubot-avatar-wrap svg {
    width: 22px;
    height: 22px;
    color: #ffffff;
}

.edubot-status-indicator {
    position: absolute;
    bottom: -1px;
    right: -1px;
    width: 11px;
    height: 11px;
    background: #10b981;
    border: 2px solid #ffffff;
    border-radius: 50%;
}

.edubot-header-details h4 {
    margin: 0;
    font-size: 0.95rem;
    font-weight: 700;
    letter-spacing: -0.2px;
    color: #ffffff;
}

.edubot-header-details p {
    margin: 2px 0 0;
    font-size: 0.72rem;
    opacity: 0.9;
    color: rgba(255, 255, 255, 0.9);
}

.edubot-header-actions {
    display: flex;
    align-items: center;
    gap: 6px;
}

.edubot-action-btn {
    background: rgba(255, 255, 255, 0.15);
    border: none;
    color: #ffffff;
    width: 32px;
    height: 32px;
    border-radius: 50%;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s, transform 0.2s;
}

.edubot-action-btn:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: scale(1.05);
}

/* Chat Messages Viewport */
.edubot-messages {
    flex: 1;
    overflow-y: auto;
    padding: 16px;
    display: flex;
    flex-direction: column;
    gap: 14px;
    background: var(--edubot-bg);
    scroll-behavior: smooth;
}

.edubot-messages::-webkit-scrollbar {
    width: 6px;
}
.edubot-messages::-webkit-scrollbar-thumb {
    background: var(--edubot-border);
    border-radius: 4px;
}

/* Welcome Card & Suggestions */
.edubot-welcome {
    background: var(--edubot-surface);
    border: 1px solid var(--edubot-border);
    border-radius: 14px;
    padding: 14px;
    text-align: center;
    margin-bottom: 6px;
}

.edubot-welcome-badge {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    background: rgba(99, 102, 241, 0.12);
    color: var(--edubot-primary);
    padding: 3px 10px;
    border-radius: 12px;
    font-size: 0.75rem;
    font-weight: 600;
    margin-bottom: 6px;
}

.edubot-welcome h5 {
    margin: 4px 0 6px;
    font-size: 0.95rem;
    color: var(--edubot-text);
}

.edubot-welcome p {
    margin: 0;
    font-size: 0.8rem;
    color: var(--edubot-text-muted);
    line-height: 1.4;
}

.edubot-suggestions {
    display: flex;
    flex-direction: column;
    gap: 6px;
    margin-top: 10px;
}

.edubot-chip {
    background: var(--edubot-bg);
    border: 1px solid var(--edubot-border);
    color: var(--edubot-text);
    padding: 7px 12px;
    border-radius: 12px;
    font-size: 0.76rem;
    text-align: left;
    cursor: pointer;
    transition: all 0.2s ease;
    display: flex;
    align-items: center;
    gap: 6px;
}

.edubot-chip:hover {
    border-color: var(--edubot-primary);
    background: rgba(99, 102, 241, 0.05);
    color: var(--edubot-primary);
    transform: translateX(3px);
}

.edubot-chip svg {
    width: 14px;
    height: 14px;
    color: var(--edubot-primary);
    flex-shrink: 0;
}

/* Message Rows */
.edubot-msg-row {
    display: flex;
    gap: 8px;
    max-width: 88%;
    animation: edubotFadeIn 0.25s ease-out;
}

@keyframes edubotFadeIn {
    from { opacity: 0; transform: translateY(6px); }
    to { opacity: 1; transform: translateY(0); }
}

.edubot-msg-row.user {
    align-self: flex-end;
    flex-direction: row-reverse;
}

.edubot-msg-row.bot {
    align-self: flex-start;
}

.edubot-msg-avatar {
    width: 28px;
    height: 28px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    font-size: 0.75rem;
}

.edubot-msg-row.bot .edubot-msg-avatar {
    background: linear-gradient(135deg, var(--edubot-primary), var(--edubot-secondary));
    color: #ffffff;
}

.edubot-msg-row.user .edubot-msg-avatar {
    background: #cbd5e1;
    color: #1e293b;
}

.edubot-msg-bubble {
    padding: 10px 14px;
    border-radius: 16px;
    font-size: 0.85rem;
    line-height: 1.5;
    word-break: break-word;
}

.edubot-msg-row.user .edubot-msg-bubble {
    background: var(--edubot-user-bubble);
    color: #ffffff;
    border-bottom-right-radius: 4px;
}

.edubot-msg-row.bot .edubot-msg-bubble {
    background: var(--edubot-bot-bubble);
    color: var(--edubot-bot-text);
    border-bottom-left-radius: 4px;
    border: 1px solid var(--edubot-border);
}

/* Markdown styling inside bot bubble */
.edubot-msg-bubble p {
    margin: 0 0 6px;
}
.edubot-msg-bubble p:last-child {
    margin-bottom: 0;
}
.edubot-msg-bubble strong {
    font-weight: 700;
}
.edubot-msg-bubble ul, .edubot-msg-bubble ol {
    margin: 4px 0 6px 18px;
    padding: 0;
}
.edubot-msg-bubble li {
    margin-bottom: 3px;
}
.edubot-msg-bubble code {
    background: rgba(0, 0, 0, 0.08);
    padding: 2px 5px;
    border-radius: 4px;
    font-size: 0.8em;
    font-family: monospace;
}
.edubot-msg-bubble pre {
    background: #0f172a;
    color: #e2e8f0;
    padding: 8px 10px;
    border-radius: 8px;
    overflow-x: auto;
    font-size: 0.78rem;
    margin: 6px 0;
}
.edubot-msg-bubble pre code {
    background: transparent;
    padding: 0;
    color: inherit;
}

/* Typing Indicator */
.edubot-typing-indicator {
    display: none;
    align-items: center;
    gap: 8px;
    padding: 4px 8px;
}

.edubot-typing-indicator.active {
    display: flex;
}

.edubot-dots {
    display: flex;
    align-items: center;
    gap: 4px;
    background: var(--edubot-bot-bubble);
    padding: 8px 12px;
    border-radius: 14px;
    border: 1px solid var(--edubot-border);
}

.edubot-dots span {
    width: 6px;
    height: 6px;
    background: var(--edubot-primary);
    border-radius: 50%;
    animation: edubotBounce 1.4s infinite ease-in-out both;
}

.edubot-dots span:nth-child(1) { animation-delay: -0.32s; }
.edubot-dots span:nth-child(2) { animation-delay: -0.16s; }
.edubot-dots span:nth-child(3) { animation-delay: 0s; }

@keyframes edubotBounce {
    0%, 80%, 100% { transform: scale(0); opacity: 0.4; }
    40% { transform: scale(1); opacity: 1; }
}

.edubot-typing-label {
    font-size: 0.72rem;
    color: var(--edubot-text-muted);
}

/* Input Bar */
.edubot-input-container {
    padding: 12px 14px 10px;
    border-top: 1px solid var(--edubot-border);
    background: var(--edubot-surface);
}

.edubot-input-box {
    display: flex;
    align-items: flex-end;
    gap: 8px;
    background: var(--edubot-bg);
    border: 1px solid var(--edubot-border);
    border-radius: 20px;
    padding: 6px 8px 6px 14px;
    box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.03);
    transition: border-color 0.2s, box-shadow 0.2s;
}

.edubot-input-box:focus-within {
    border-color: var(--edubot-primary);
    box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.15);
}

.edubot-textarea {
    flex: 1;
    border: none;
    background: transparent;
    color: var(--edubot-text);
    font-size: 0.85rem;
    font-family: inherit;
    resize: none;
    outline: none;
    max-height: 90px;
    min-height: 22px;
    line-height: 1.4;
    padding: 4px 0;
}

.edubot-send-btn {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    background: var(--edubot-primary);
    border: none;
    color: #ffffff;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    transition: background 0.2s, transform 0.15s;
    outline: none;
}

.edubot-send-btn:hover {
    background: var(--edubot-primary-hover);
    transform: scale(1.05);
}

.edubot-send-btn:active {
    transform: scale(0.92);
}

.edubot-send-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    transform: none;
}

.edubot-footer-meta {
    margin-top: 6px;
    text-align: center;
    font-size: 0.68rem;
    color: var(--edubot-text-muted);
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 5px;
}

.edubot-footer-meta span {
    font-weight: 600;
    color: var(--edubot-primary);
}

/* Mobile responsive */
@media (max-width: 480px) {
    .edubot-launcher {
        bottom: 16px;
        right: 16px;
        width: 54px;
        height: 54px;
    }
    .edubot-container {
        bottom: 80px;
        right: 12px;
        left: 12px;
        width: auto;
        height: calc(100vh - 100px);
        max-height: 560px;
        border-radius: 18px;
    }
}
</style>

<!-- Floating Launcher Button -->
<button class="edubot-launcher" id="edubotLauncher" type="button" aria-label="Ask EduBot AI Assistant" title="Ask EduBot AI">
    <div class="edubot-launcher-pulse"></div>
    <span class="edubot-launcher-tooltip">Ask EduBot AI 💬</span>
    
    <div class="edubot-launcher-icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M12 2a2 2 0 0 1 2 2v2a2 2 0 0 1-2 2 2 2 0 0 1-2-2V4a2 2 0 0 1 2-2z"/>
            <rect x="3" y="8" width="18" height="12" rx="4"/>
            <circle cx="9" cy="13" r="1.5" fill="currentColor"/>
            <circle cx="15" cy="13" r="1.5" fill="currentColor"/>
            <path d="M10 17h4"/>
        </svg>
    </div>

    <div class="edubot-launcher-close">
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
        </svg>
    </div>
</button>

<!-- Chat Window Dialog -->
<div class="edubot-container" id="edubotContainer" role="dialog" aria-label="EduBot AI Assistant" data-api="{$apiAttr}" data-suggestions="{$suggestionsAttr}">
    <!-- Header -->
    <div class="edubot-header">
        <div class="edubot-header-profile">
            <div class="edubot-avatar-wrap">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="7" width="18" height="13" rx="3"/>
                    <path d="M16 3l-4 4-4-4"/>
                    <circle cx="9" cy="13" r="1" fill="currentColor"/>
                    <circle cx="15" cy="13" r="1" fill="currentColor"/>
                </svg>
                <div class="edubot-status-indicator"></div>
            </div>
            <div class="edubot-header-details">
                <h4>EduBot AI</h4>
                <p>Website Guide & Academic Tutor</p>
            </div>
        </div>
        <div class="edubot-header-actions">
            <button class="edubot-action-btn" id="edubotClearBtn" type="button" title="Clear Chat History">
                <svg xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M3 6h18"></path>
                    <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path>
                    <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path>
                </svg>
            </button>
            <button class="edubot-action-btn" id="edubotCloseBtn" type="button" title="Close Chat">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        </div>
    </div>

    <!-- Messages Container -->
    <div class="edubot-messages" id="edubotMessages">
        <!-- Welcome Card -->
        <div class="edubot-welcome" id="edubotWelcome">
            <div class="edubot-welcome-badge">✨ AI Ready</div>
            <h5>Hello, {$currentNameEscaped}! 👋</h5>
            <p>I'm your EduSys assistant. Ask me anything about using the website, your classes, or any subject doubt!</p>
            <div class="edubot-suggestions" id="edubotSuggestionsList"></div>
        </div>

        <!-- Typing Indicator -->
        <div class="edubot-typing-indicator" id="edubotTyping">
            <div class="edubot-dots">
                <span></span><span></span><span></span>
            </div>
            <span class="edubot-typing-label">EduBot is typing...</span>
        </div>
    </div>

    <!-- Input Box -->
    <div class="edubot-input-container">
        <div class="edubot-input-box">
            <textarea
                class="edubot-textarea"
                id="edubotInput"
                placeholder="Ask any website question or subject doubt..."
                rows="1"
            ></textarea>
            <button class="edubot-send-btn" id="edubotSendBtn" type="button" title="Send (Enter)">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="22" y1="2" x2="11" y2="13"></line>
                    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                </svg>
            </button>
        </div>
        <div class="edubot-footer-meta">
           
        </div>
    </div>
</div>

<script src="{$widgetBaseUrl}js/edubot.js?v=2.4"></script>
HTML;
