<?php
/**
 * EduBot Chat Widget - Include this in any page to show the AI assistant
 * Usage: require_once __DIR__ . '/includes/chatbot_widget.php'; echo $chatbotWidget;
 */

$chatbotWidget = <<<HTML
<!-- EduBot Chat Widget -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
/* Chat Widget Styles */
:root {
    --chat-primary: #6c63ff;
    --chat-primary-hover: #5a52e0;
    --chat-bg: #ffffff;
    --chat-text: #2d3748;
    --chat-text-secondary: #718096;
    --chat-border: #e2e8f0;
    --chat-user-bubble: #6c63ff;
    --chat-bot-bubble: #f1f5f9;
    --chat-input-bg: #f8fafc;
}

[data-theme="dark"] {
    --chat-bg: #1e2235;
    --chat-text: #e2e8f0;
    --chat-text-secondary: #a0aec0;
    --chat-border: #2d3748;
    --chat-bot-bubble: #2d3748;
    --chat-input-bg: #22263a;
}

.edubot-toggle {
    position: fixed;
    bottom: 24px;
    right: 24px;
    width: 60px;
    height: 60px;
    border-radius: 50%;
    background: linear-gradient(135deg, var(--chat-primary), #8b5cf6);
    border: none;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 8px 32px rgba(108, 99, 255, 0.4);
    z-index: 9999;
    transition: transform 0.3s ease, box-shadow 0.3s ease;
    animation: pulse 2s infinite;
}

.edubot-toggle:hover {
    transform: scale(1.1);
    box-shadow: 0 12px 40px rgba(108, 99, 255, 0.5);
}

.edubot-toggle:active {
    transform: scale(0.95);
}

.edubot-toggle svg {
    width: 28px;
    height: 28px;
    color: white;
    stroke-width: 2.5;
}

.edubot-toggle .notification-badge {
    position: absolute;
    top: 4px;
    right: 4px;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: #ff5f5f;
    color: white;
    font-size: 11px;
    font-weight: 700;
    display: flex;
    align-items: center;
    justify-content: center;
    opacity: 0;
    transform: scale(0);
    transition: opacity 0.3s, transform 0.3s;
}

.edubot-toggle.has-notification .notification-badge {
    opacity: 1;
    transform: scale(1);
}

@keyframes pulse {
    0%, 100% { box-shadow: 0 8px 32px rgba(108, 99, 255, 0.4); }
    50% { box-shadow: 0 8px 32px rgba(108, 99, 255, 0.6), 0 0 0 8px rgba(108, 99, 255, 0.1); }
}

.edubot-window {
    position: fixed;
    bottom: 100px;
    right: 24px;
    width: 380px;
    height: 550px;
    max-height: 80vh;
    background: var(--chat-bg);
    border-radius: 20px;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15), 0 0 0 1px var(--chat-border);
    display: none;
    flex-direction: column;
    overflow: hidden;
    z-index: 9998;
    transform: translateY(20px) scale(0.95);
    opacity: 0;
    transition: transform 0.3s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.3s ease;
}

.edubot-window.open {
    display: flex;
    transform: translateY(0) scale(1);
    opacity: 1;
}

.edubot-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 16px 20px;
    background: linear-gradient(135deg, var(--chat-primary), #8b5cf6);
    color: white;
    border-radius: 20px 20px 0 0;
}

.edubot-header-info {
    display: flex;
    align-items: center;
    gap: 12px;
}

.edubot-avatar {
    width: 44px;
    height: 44px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.2);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 20px;
}

.edubot-header-text h3 {
    margin: 0;
    font-size: 1rem;
    font-weight: 700;
}

.edubot-header-text span {
    font-size: 0.75rem;
    opacity: 0.9;
    display: flex;
    align-items: center;
    gap: 6px;
}

.edubot-status-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #4ade80;
    animation: blink 2s infinite;
}

@keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}

.edubot-close {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.15);
    border: none;
    color: white;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s;
}

.edubot-close:hover {
    background: rgba(255, 255, 255, 0.3);
}

.edubot-messages {
    flex: 1;
    overflow-y: auto;
    padding: 20px;
    display: flex;
    flex-direction: column;
    gap: 16px;
    background: var(--chat-bg);
}

.edubot-message {
    display: flex;
    gap: 10px;
    max-width: 85%;
    animation: slideIn 0.3s ease;
}

@keyframes slideIn {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
}

.edubot-message.bot {
    align-self: flex-start;
}

.edubot-message.user {
    align-self: flex-end;
    flex-direction: row-reverse;
}

.edubot-message-avatar {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 14px;
    flex-shrink: 0;
}

.edubot-message.bot .edubot-message-avatar {
    background: var(--chat-primary);
    color: white;
}

.edubot-message.user .edubot-message-avatar {
    background: var(--chat-text-secondary);
    color: white;
}

.edubot-message-content {
    background: var(--chat-bot-bubble);
    border-radius: 16px;
    padding: 12px 16px;
    font-size: 0.9rem;
    line-height: 1.5;
    color: var(--chat-text);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.edubot-message.user .edubot-message-content {
    background: var(--chat-user-bubble);
    color: white;
    border-radius: 16px 16px 4px 16px;
}

.edubot-message.bot .edubot-message-content {
    border-radius: 16px 16px 16px 4px;
}

.edubot-typing {
    display: none;
    align-items: center;
    gap: 4px;
    padding: 8px 16px;
    color: var(--chat-text-secondary);
    font-size: 0.85rem;
}

.edubot-typing.show {
    display: flex;
}

.edubot-typing-dots {
    display: flex;
    gap: 3px;
}

.edubot-typing-dots span {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: var(--chat-primary);
    animation: typing 1.4s infinite ease-in-out;
}

.edubot-typing-dots span:nth-child(2) { animation-delay: 0.2s; }
.edubot-typing-dots span:nth-child(3) { animation-delay: 0.4s; }

@keyframes typing {
    0%, 60%, 100% { transform: translateY(0); opacity: 0.4; }
    30% { transform: translateY(-6px); opacity: 1; }
}

.edubot-input-area {
    padding: 16px 20px;
    border-top: 1px solid var(--chat-border);
    background: var(--chat-bg);
    border-radius: 0 0 20px 20px;
}

.edubot-quick-actions {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    margin-bottom: 12px;
}

.edubot-quick-btn {
    padding: 6px 12px;
    border-radius: 16px;
    border: 1px solid var(--chat-border);
    background: var(--chat-input-bg);
    color: var(--chat-text-secondary);
    font-size: 0.75rem;
    cursor: pointer;
    transition: all 0.2s;
}

.edubot-quick-btn:hover {
    border-color: var(--chat-primary);
    color: var(--chat-primary);
    background: rgba(108, 99, 255, 0.1);
}

.edubot-input-row {
    display: flex;
    gap: 10px;
    align-items: flex-end;
}

.edubot-input-wrapper {
    flex: 1;
    position: relative;
}

.edubot-input {
    width: 100%;
    padding: 12px 48px 12px 16px;
    border-radius: 24px;
    border: 1px solid var(--chat-border);
    background: var(--chat-input-bg);
    color: var(--chat-text);
    font-size: 0.9rem;
    font-family: inherit;
    outline: none;
    resize: none;
    min-height: 48px;
    max-height: 120px;
    transition: border-color 0.2s, box-shadow 0.2s;
}

.edubot-input:focus {
    border-color: var(--chat-primary);
    box-shadow: 0 0 0 3px rgba(108, 99, 255, 0.15);
}

.edubot-send {
    width: 44px;
    height: 44px;
    border-radius: 50%;
    background: var(--chat-primary);
    border: none;
    color: white;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: transform 0.2s, background 0.2s;
    flex-shrink: 0;
}

.edubot-send:hover {
    transform: scale(1.05);
    background: var(--chat-primary-hover);
}

.edubot-send:disabled {
    opacity: 0.5;
    cursor: not-allowed;
    transform: none;
}

.edubot-send svg {
    width: 20px;
    height: 20px;
}

.edubot-empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    color: var(--chat-text-secondary);
    text-align: center;
    padding: 20px;
}

.edubot-empty-state svg {
    width: 64px;
    height: 64px;
    margin-bottom: 16px;
    opacity: 0.5;
}

.edubot-empty-state h4 {
    margin: 0 0 8px;
    font-size: 1rem;
}

.edubot-empty-state p {
    margin: 0;
    font-size: 0.85rem;
    line-height: 1.5;
}

/* Mobile responsive */
@media (max-width: 480px) {
    .edubot-window {
        width: calc(100vw - 32px);
        height: calc(100vh - 120px);
        max-height: 70vh;
        bottom: 90px;
        right: 16px;
        border-radius: 16px;
    }
    .edubot-toggle {
        bottom: 16px;
        right: 16px;
        width: 56px;
        height: 56px;
    }
}
</style>

<!-- Chat Toggle Button -->
<button class="edubot-toggle" id="edubotToggle" aria-label="Open EduBot Assistant">
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
    </svg>
    <span class="notification-badge" id="edubotBadge">1</span>
</button>

<!-- Chat Window -->
<div class="edubot-window" id="edubotWindow" role="dialog" aria-label="EduBot Assistant">
    <div class="edubot-header">
        <div class="edubot-header-info">
            <div class="edubot-avatar">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="20" height="20">
                    <rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect>
                    <line x1="8" y1="21" x2="16" y2="21"></line>
                    <line x1="12" y1="17" x2="12" y2="21"></line>
                </svg>
            </div>
            <div class="edubot-header-text">
                <h3>EduBot</h3>
                <span><span class="edubot-status-dot"></span> Online</span>
            </div>
        </div>
        <button class="edubot-close" id="edubotClose" aria-label="Close chat">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" width="20" height="20">
                <line x1="18" y1="6" x2="6" y2="18"></line>
                <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
        </button>
    </div>

    <div class="edubot-messages" id="edubotMessages">
        <div class="edubot-empty-state" id="edubotEmptyState">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
            </svg>
            <h4>Hi! I'm EduBot 👋</h4>
            <p>Ask me anything about EduSys features, your classes, assignments, or education topics!</p>
        </div>

        <div class="edubot-typing" id="edubotTyping">
            <div class="edubot-typing-dots">
                <span></span><span></span><span></span>
            </div>
            <span>EduBot is typing...</span>
        </div>
    </div>

    <div class="edubot-input-area">
        <div class="edubot-quick-actions" id="edubotQuickActions">
            <button class="edubot-quick-btn" data-q="How do I join a live class?">Join Live Class</button>
            <button class="edubot-quick-btn" data-q="How to submit an assignment?">Submit Assignment</button>
            <button class="edubot-quick-btn" data-q="Where are my recordings?">View Recordings</button>
            <button class="edubot-quick-btn" data-q="How to check my attendance?">Check Attendance</button>
        </div>
        <div class="edubot-input-row">
            <div class="edubot-input-wrapper">
                <textarea
                    class="edubot-input"
                    id="edubotInput"
                    placeholder="Type your question..."
                    rows="1"
                    aria-label="Your message"
                ></textarea>
            </div>
            <button class="edubot-send" id="edubotSend" aria-label="Send message">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="22" y1="2" x2="11" y2="13"></line>
                    <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
                </svg>
            </button>
        </div>
    </div>
</div>

<script>
// EduBot Chat Widget Logic
(function() {
    'use strict';

    const STORAGE_KEY = 'edubot_conversation';
    const API_URL = '<?= BASE_URL ?>php/chatbot_api.php';

    // DOM Elements
    const toggleBtn = document.getElementById('edubotToggle');
    const windowEl = document.getElementById('edubotWindow');
    const closeBtn = document.getElementById('edubotClose');
    const messagesEl = document.getElementById('edubotMessages');
    const emptyState = document.getElementById('edubotEmptyState');
    const typingEl = document.getElementById('edubotTyping');
    const inputEl = document.getElementById('edubotInput');
    const sendBtn = document.getElementById('edubotSend');
    const quickActions = document.getElementById('edubotQuickActions');
    const badge = document.getElementById('edubotBadge');

    // State
    let conversation = [];
    let isOpen = false;
    let isTyping = false;

    // Initialize
    function init() {
        loadConversation();
        bindEvents();
        updateBadge();
    }

    function loadConversation() {
        try {
            const stored = localStorage.getItem(STORAGE_KEY);
            if (stored) {
                conversation = JSON.parse(stored);
                renderMessages();
            }
        } catch (e) {
            conversation = [];
        }
    }

    function saveConversation() {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(conversation));
    }

    function bindEvents() {
        toggleBtn.addEventListener('click', toggleChat);
        closeBtn.addEventListener('click', closeChat);
        sendBtn.addEventListener('click', sendMessage);

        inputEl.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });

        inputEl.addEventListener('input', autoResize);

        quickActions.addEventListener('click', (e) => {
            const btn = e.target.closest('.edubot-quick-btn');
            if (btn) {
                inputEl.value = btn.dataset.q;
                autoResize();
                sendMessage();
            }
        });

        // Close on outside click
        document.addEventListener('click', (e) => {
            if (isOpen && !windowEl.contains(e.target) && !toggleBtn.contains(e.target)) {
                closeChat();
            }
        });

        // Escape key to close
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && isOpen) {
                closeChat();
            }
        });
    }

    function autoResize() {
        inputEl.style.height = 'auto';
        inputEl.style.height = Math.min(inputEl.scrollHeight, 120) + 'px';
    }

    function toggleChat() {
        isOpen ? closeChat() : openChat();
    }

    function openChat() {
        isOpen = true;
        windowEl.classList.add('open');
        toggleBtn.classList.add('hidden');
        inputEl.focus();
        badge.style.opacity = '0';
        badge.style.transform = 'scale(0)';
        toggleBtn.classList.remove('has-notification');
    }

    function closeChat() {
        isOpen = false;
        windowEl.classList.remove('open');
        toggleBtn.classList.remove('hidden');
    }

    function updateBadge() {
        const unread = conversation.filter(m => m.role === 'bot' && !m.read).length;
        if (unread > 0 && !isOpen) {
            badge.textContent = unread > 9 ? '9+' : unread;
            badge.style.opacity = '1';
            badge.style.transform = 'scale(1)';
            toggleBtn.classList.add('has-notification');
        }
    }

    function addMessage(role, content) {
        const msg = {
            role,
            content,
            timestamp: Date.now(),
            read: role === 'user'
        };
        conversation.push(msg);
        saveConversation();
        renderMessages();
        updateBadge();
        return msg;
    }

    function renderMessages() {
        if (conversation.length === 0) {
            emptyState.style.display = 'flex';
            return;
        }
        emptyState.style.display = 'none';

        // Keep empty state but append messages
        messagesEl.innerHTML = '';
        messagesEl.appendChild(emptyState);
        emptyState.style.display = 'none';

        conversation.forEach(msg => {
            const el = createMessageElement(msg);
            messagesEl.appendChild(el);
        });

        scrollToBottom();
    }

    function createMessageElement(msg) {
        const div = document.createElement('div');
        div.className = `edubot-message ${msg.role}`;

        const avatarIcon = msg.role === 'bot'
            ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="16" height="16"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line></svg>'
            : '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" width="16" height="16"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>';

        div.innerHTML = `
            <div class="edubot-message-avatar">${avatarIcon}</div>
            <div class="edubot-message-content">${escapeHtml(msg.content)}</div>
        `;

        return div;
    }

    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    function scrollToBottom() {
        messagesEl.scrollTop = messagesEl.scrollHeight;
    }

    function showTyping(show) {
        isTyping = show;
        typingEl.classList.toggle('show', show);
        sendBtn.disabled = show;
        if (show) scrollToBottom();
    }

    async function sendMessage() {
        const text = inputEl.value.trim();
        if (!text || isTyping) return;

        // Add user message
        addMessage('user', text);
        inputEl.value = '';
        inputEl.style.height = 'auto';
        sendBtn.disabled = true;

        // Show typing indicator
        showTyping(true);

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: text,
                    context: conversation.slice(-10)
                })
            });

            const data = await response.json();

            showTyping(false);

            if (data.success) {
                addMessage('bot', data.reply);
            } else {
                addMessage('bot', 'Sorry, I encountered an error. Please try again.');
                console.error('Chatbot error:', data.msg);
            }
        } catch (error) {
            showTyping(false);
            addMessage('bot', 'Sorry, I\'m having trouble connecting. Please check your connection and try again.');
            console.error('Chatbot fetch error:', error);
        } finally {
            sendBtn.disabled = false;
        }
    }

    // Initialize when DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
</script>
HTML;