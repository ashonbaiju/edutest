/**
 * EduBot AI Assistant - Interactive Chat Widget Client
 */
(function() {
    'use strict';

    const STORAGE_KEY = 'edubot_chat_history_v1';

    const launcher = document.getElementById('edubotLauncher');
    const container = document.getElementById('edubotContainer');
    if (!launcher || !container) return;

    const apiEndpoint = container.dataset.api || '/edu/project/php/chatbot_api.php';
    let suggestions = [];
    try {
        suggestions = JSON.parse(container.dataset.suggestions || '[]');
    } catch (e) {
        suggestions = [];
    }

    const closeBtn = document.getElementById('edubotCloseBtn');
    const clearBtn = document.getElementById('edubotClearBtn');
    const messagesBox = document.getElementById('edubotMessages');
    const welcomeBox = document.getElementById('edubotWelcome');
    const suggestionsList = document.getElementById('edubotSuggestionsList');
    const inputArea = document.getElementById('edubotInput');
    const sendBtn = document.getElementById('edubotSendBtn');
    const typingIndicator = document.getElementById('edubotTyping');

    let history = [];
    let isSending = false;

    function init() {
        renderSuggestions();
        loadHistory();
        setupListeners();
    }

    function renderSuggestions() {
        if (!suggestionsList || !Array.isArray(suggestions)) return;
        suggestionsList.innerHTML = '';
        suggestions.forEach(function(text) {
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'edubot-chip';
            btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg> ' + escapeHtml(text);
            btn.addEventListener('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                if (inputArea) {
                    inputArea.value = text;
                    sendMessage();
                }
            });
            suggestionsList.appendChild(btn);
        });
    }

    function loadHistory() {
        try {
            const raw = localStorage.getItem(STORAGE_KEY);
            if (raw) {
                history = JSON.parse(raw);
                if (Array.isArray(history) && history.length > 0) {
                    if (welcomeBox) welcomeBox.style.display = 'none';
                    history.forEach(function(item) {
                        appendMessageDOM(item.role, item.content, false);
                    });
                    scrollToBottom();
                }
            }
        } catch (e) {
            history = [];
        }
    }

    function saveHistory() {
        try {
            const trimmed = history.slice(-25);
            localStorage.setItem(STORAGE_KEY, JSON.stringify(trimmed));
        } catch (e) {}
    }

    function setupListeners() {
        launcher.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            toggleChat();
        });

        if (closeBtn) {
            closeBtn.addEventListener('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                closeChat();
            });
        }

        if (clearBtn) {
            clearBtn.addEventListener('click', function(e) {
                e.preventDefault();
                e.stopPropagation();
                clearChat();
            });
        }

        if (sendBtn) {
            sendBtn.addEventListener('click', function(e) {
                e.preventDefault();
                sendMessage();
            });
        }

        if (inputArea) {
            inputArea.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    sendMessage();
                }
            });

            inputArea.addEventListener('input', function() {
                this.style.height = 'auto';
                this.style.height = Math.min(this.scrollHeight, 90) + 'px';
            });
        }

        // Close on Escape key
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape' && container.classList.contains('is-open')) {
                closeChat();
            }
        });

        // Close when clicking outside of the chat window
        document.addEventListener('click', function(e) {
            if (container.classList.contains('is-open')) {
                if (!container.contains(e.target) && !launcher.contains(e.target)) {
                    closeChat();
                }
            }
        });
    }

    function toggleChat() {
        if (container.classList.contains('is-open')) {
            closeChat();
        } else {
            openChat();
        }
    }

    function openChat() {
        container.classList.add('is-open');
        launcher.classList.add('is-active');
        if (inputArea) {
            setTimeout(function() {
                inputArea.focus();
            }, 100);
        }
        scrollToBottom();
    }

    function closeChat() {
        container.classList.remove('is-open');
        launcher.classList.remove('is-active');
    }

    function clearChat() {
        if (!confirm('Clear all conversation messages?')) return;
        history = [];
        localStorage.removeItem(STORAGE_KEY);
        const allRows = messagesBox.querySelectorAll('.edubot-msg-row');
        allRows.forEach(function(r) { r.remove(); });
        if (welcomeBox) welcomeBox.style.display = 'block';
    }

    function scrollToBottom() {
        setTimeout(function() {
            if (messagesBox) {
                messagesBox.scrollTop = messagesBox.scrollHeight;
            }
        }, 50);
    }

    function escapeHtml(str) {
        const d = document.createElement('div');
        d.textContent = str || '';
        return d.innerHTML;
    }

    // Markdown formatter
    function formatMarkdown(text) {
        if (!text) return '';
        let escaped = escapeHtml(text);

        // Code blocks: ```code```
        escaped = escaped.replace(/```([a-zA-Z0-9_-]*)\n([\s\S]*?)```/g, function(match, lang, code) {
            return '<pre><code>' + code + '</code></pre>';
        });

        // Inline code: `code`
        escaped = escaped.replace(/`([^`]+)`/g, '<code>$1</code>');

        // Bold: **text** or __text__
        escaped = escaped.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
        escaped = escaped.replace(/__([^_]+)__/g, '<strong>$1</strong>');

        // Italics: *text*
        escaped = escaped.replace(/\*([^*]+)\*/g, '<em>$1</em>');

        // Process line breaks and lists
        const lines = escaped.split('\n');
        let html = '';
        let inList = false;
        let inOrdered = false;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line.startsWith('&bull;') || line.startsWith('- ') || line.startsWith('* ')) {
                if (!inList) {
                    if (inOrdered) { html += '</ol>'; inOrdered = false; }
                    html += '<ul>';
                    inList = true;
                }
                const content = line.replace(/^(&bull;|-|\*)\s*/, '');
                html += '<li>' + content + '</li>';
            } else if (/^[0-9]+\.\s+/.test(line)) {
                if (!inOrdered) {
                    if (inList) { html += '</ul>'; inList = false; }
                    html += '<ol>';
                    inOrdered = true;
                }
                const content = line.replace(/^[0-9]+\.\s+/, '');
                html += '<li>' + content + '</li>';
            } else {
                if (inList) { html += '</ul>'; inList = false; }
                if (inOrdered) { html += '</ol>'; inOrdered = false; }
                if (line === '') {
                    html += '<br>';
                } else {
                    html += '<p>' + line + '</p>';
                }
            }
        }
        if (inList) html += '</ul>';
        if (inOrdered) html += '</ol>';

        return html;
    }

    function appendMessageDOM(role, content, animate) {
        if (animate === undefined) animate = true;
        if (welcomeBox) welcomeBox.style.display = 'none';

        const row = document.createElement('div');
        row.className = 'edubot-msg-row ' + role;
        if (!animate) row.style.animation = 'none';

        const avatar = document.createElement('div');
        avatar.className = 'edubot-msg-avatar';
        avatar.innerHTML = (role === 'bot')
            ? '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><rect x="3" y="7" width="18" height="13" rx="3"/><path d="M16 3l-4 4-4-4"/></svg>'
            : '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>';

        const bubble = document.createElement('div');
        bubble.className = 'edubot-msg-bubble';

        if (role === 'bot') {
            bubble.innerHTML = formatMarkdown(content);
        } else {
            bubble.textContent = content;
        }

        row.appendChild(avatar);
        row.appendChild(bubble);

        if (typingIndicator && messagesBox) {
            messagesBox.insertBefore(row, typingIndicator);
        } else if (messagesBox) {
            messagesBox.appendChild(row);
        }
    }

    async function sendMessage() {
        if (!inputArea) return;
        const text = inputArea.value.trim();
        if (!text || isSending) return;

        isSending = true;
        if (sendBtn) sendBtn.disabled = true;
        inputArea.value = '';
        inputArea.style.height = 'auto';

        history.push({ role: 'user', content: text });
        appendMessageDOM('user', text);
        saveHistory();
        scrollToBottom();

        if (typingIndicator) {
            typingIndicator.classList.add('active');
        }
        scrollToBottom();

        try {
            const res = await fetch(apiEndpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    message: text,
                    context: history.slice(-8)
                })
            });

            const data = await res.json();
            if (typingIndicator) {
                typingIndicator.classList.remove('active');
            }

            if (data && data.success && data.reply) {
                history.push({ role: 'bot', content: data.reply });
                appendMessageDOM('bot', data.reply);
                saveHistory();
            } else {
                const err = (data && data.msg) ? data.msg : 'Failed to reach AI service.';
                appendMessageDOM('bot', '⚠️ ' + err);
            }
        } catch (err) {
            if (typingIndicator) {
                typingIndicator.classList.remove('active');
            }
            appendMessageDOM('bot', '⚠️ Connection error. Please check your network or try again.');
            console.error('EduBot error:', err);
        } finally {
            isSending = false;
            if (sendBtn) sendBtn.disabled = false;
            scrollToBottom();
            if (inputArea) inputArea.focus();
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();

