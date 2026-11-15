<?php
/**
 * AI Configuration Template - EduSys
 * Copy this file to config/ai.php and insert your Groq API key
 */

// Groq API Key (Get free key from https://console.groq.com/keys)
define('GROQ_API_KEY', 'YOUR_GROQ_API_KEY_HERE');

// Primary Model
define('GROQ_MODEL', 'openai/gpt-oss-120b');

// Fallback models if primary model is rate-limited or busy
define('GROQ_FALLBACK_MODELS', [
    'qwen/qwen3.8-27b',
    'openai/gpt-oss-20b'
]);
