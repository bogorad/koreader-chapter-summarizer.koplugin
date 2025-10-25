# OpenRouter API Documentation

## Table of Contents
- [Overview](#overview)
- [Getting Started](#getting-started)
- [Authentication](#authentication)
- [API Endpoints](#api-endpoints)
- [Request Format](#request-format)
- [Response Format](#response-format)
- [Error Handling](#error-handling)
- [Streaming](#streaming)
- [Models](#models)
- [Best Practices](#best-practices)
- [Code Examples](#code-examples)

## Overview

### What is OpenRouter?

OpenRouter provides a unified API that gives you access to **hundreds of AI models** through a single endpoint. It automatically handles:
- Model routing and fallbacks
- Cost optimization
- Provider selection
- Rate limiting
- Error handling

### Key Benefits

- **Single API Key**: Access multiple model providers (OpenAI, Anthropic, Google, Meta, etc.)
- **Automatic Fallback**: Switches to backup providers if primary fails
- **Cost Comparison**: Compare pricing across different models instantly
- **OpenAI Compatible**: Works with existing OpenAI SDK code by changing the endpoint
- **Real-Time Routing**: Routes requests to fastest available provider

### Base URL

```
https://openrouter.ai/api/v1
```

## Getting Started

### 1. Create an Account

Visit [https://openrouter.ai/](https://openrouter.ai/) and sign up for an account.

### 2. Get API Key

1. Go to [https://openrouter.ai/keys](https://openrouter.ai/keys)
2. Click "Create Key"
3. Give it a name and optional credit limit
4. Copy the API key (starts with `sk-or-...`)

⚠️ **Important**: Keep your API key secure! Never commit it to public repositories.

### 3. Add Credits

OpenRouter uses a credit system:
- Add credits to your account
- Credits are deducted based on model usage
- Different models have different pricing
- View pricing at [https://openrouter.ai/models](https://openrouter.ai/models)

## Authentication

### Bearer Token Authentication

All API requests require authentication using a Bearer token in the `Authorization` header:

```
Authorization: Bearer YOUR_API_KEY
```

### Security Best Practices

1. **Never hardcode API keys** in your source code
2. **Use environment variables** to store keys
3. **Delete compromised keys** immediately from your account
4. **Set credit limits** to prevent unexpected charges
5. **Monitor usage** regularly in your dashboard

### Example Headers

```javascript
const headers = {
    'Authorization': 'Bearer sk-or-v1-...',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://yourapp.com',  // Optional: for attribution
    'X-Title': 'Your App Name',              // Optional: for attribution
};
```

## API Endpoints

### Chat Completions

Create a chat completion with AI models.

**Endpoint**: `POST /api/v1/chat/completions`

This is the main endpoint for generating AI responses. It's compatible with OpenAI's Chat API format.

### List Models

Get available models and their details.

**Endpoint**: `GET /api/v1/models`

Returns a list of all available models with pricing and capabilities.

### Get Generation Stats

Retrieve detailed statistics for a generation.

**Endpoint**: `GET /api/v1/generation?id={generation_id}`

Get token counts, costs, and other metadata for a completed generation.

## Request Format

### Basic Structure

```typescript
{
  // Required
  model: string;
  messages: Array<{
    role: 'user' | 'assistant' | 'system';
    content: string;
  }>;

  // Optional Parameters
  temperature?: number;        // 0.0 to 2.0
  max_tokens?: number;         // Maximum tokens to generate
  top_p?: number;              // 0.0 to 1.0
  top_k?: number;              // Integer
  frequency_penalty?: number;  // -2.0 to 2.0
  presence_penalty?: number;   // -2.0 to 2.0
  repetition_penalty?: number; // 0.0 to 2.0
  stream?: boolean;            // Enable streaming
  stop?: string | string[];    // Stop sequences
  
  // OpenRouter Specific
  provider?: {
    order?: string[];
    require_parameters?: boolean;
  };
  models?: string[];           // Fallback models
  route?: 'fallback';
}
```

### Message Format

Messages can include text and images:

```typescript
{
  role: 'user',
  content: 'What is in this image?',
}

// Or with image
{
  role: 'user',
  content: [
    {
      type: 'text',
      text: 'What is in this image?'
    },
    {
      type: 'image_url',
      image_url: {
        url: 'https://example.com/image.jpg'
        // or base64: 'data:image/jpeg;base64,...'
      }
    }
  ]
}
```

### System Messages

Use system messages to set behavior:

```typescript
{
  messages: [
    {
      role: 'system',
      content: 'You are a helpful assistant that answers concisely.'
    },
    {
      role: 'user',
      content: 'What is the capital of France?'
    }
  ]
}
```

### Parameter Descriptions

#### Temperature (0.0 - 2.0)
Controls randomness in responses:
- `0.0`: Deterministic, same output each time
- `1.0`: Default, balanced creativity
- `2.0`: Maximum creativity and randomness

#### Max Tokens
Maximum number of tokens to generate:
- Limits response length
- Helps control costs
- Different models have different max limits

#### Top P (0.0 - 1.0)
Nucleus sampling:
- `1.0`: Consider all tokens
- `0.1`: Only consider top 10% probability tokens
- Lower values = more focused responses

#### Top K
Limits token selection to top K options:
- `1`: Most predictable (always picks highest probability)
- Higher values: More variety

#### Frequency Penalty (-2.0 - 2.0)
Reduces repetition of tokens:
- Positive: Discourages repeated tokens
- Negative: Encourages repeated tokens
- Based on frequency in the output

#### Presence Penalty (-2.0 - 2.0)
Reduces repetition of topics:
- Positive: Encourages new topics
- Negative: Stays on topic
- Based on presence in the output

## Response Format

### Standard Response

```typescript
{
  id: string;                // Generation ID
  model: string;             // Model used
  object: string;            // 'chat.completion'
  created: number;           // Unix timestamp
  
  choices: Array<{
    index: number;
    message: {
      role: 'assistant';
      content: string;
    };
    finish_reason: string;   // 'stop', 'length', 'content_filter'
    native_finish_reason: string;  // Raw finish reason from provider
  }>;
  
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}
```

### Example Response

```json
{
  "id": "gen-1234567890",
  "model": "openai/gpt-4o",
  "object": "chat.completion",
  "created": 1699999999,
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "The capital of France is Paris."
      },
      "finish_reason": "stop",
      "native_finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 15,
    "completion_tokens": 8,
    "total_tokens": 23
  }
}
```

### Finish Reasons

- **stop**: Model reached natural stopping point
- **length**: Hit max_tokens limit
- **content_filter**: Content was filtered
- **tool_calls**: Model wants to call a tool
- **error**: An error occurred

## Error Handling

### HTTP Status Codes

- **200**: Success
- **400**: Bad Request (invalid parameters)
- **401**: Unauthorized (invalid API key)
- **402**: Payment Required (insufficient credits)
- **403**: Forbidden (API key doesn't have access)
- **429**: Too Many Requests (rate limited)
- **500**: Internal Server Error
- **502**: Bad Gateway (upstream provider error)
- **503**: Service Unavailable

### Error Response Format

```json
{
  "error": {
    "message": "Invalid API key",
    "type": "invalid_request_error",
    "code": "invalid_api_key",
    "metadata": {
      "provider": "openai",
      "raw_error": "..."
    }
  }
}
```

### Handling Errors

```javascript
try {
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const error = await response.json();
    
    if (response.status === 401) {
      throw new Error('Invalid API key');
    } else if (response.status === 402) {
      throw new Error('Insufficient credits');
    } else if (response.status === 429) {
      throw new Error('Rate limited, please try again later');
    } else {
      throw new Error(error.error?.message || 'Unknown error');
    }
  }

  const data = await response.json();
  return data;
} catch (error) {
  console.error('API Error:', error);
  throw error;
}
```

## Streaming

### Enable Streaming

Set `stream: true` in your request:

```javascript
const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    model: 'openai/gpt-4o',
    messages: [{role: 'user', content: 'Tell me a story'}],
    stream: true,
  }),
});
```

### Process Stream

```javascript
const reader = response.body.getReader();
const decoder = new TextDecoder();

while (true) {
  const { done, value } = await reader.read();
  if (done) break;
  
  const chunk = decoder.decode(value);
  const lines = chunk.split('\n');
  
  for (const line of lines) {
    if (line.startsWith('data: ')) {
      const data = line.slice(6);
      
      if (data === '[DONE]') {
        break;
      }
      
      try {
        const json = JSON.parse(data);
        const content = json.choices[0]?.delta?.content;
        if (content) {
          process.stdout.write(content);
        }
      } catch (e) {
        // Ignore parse errors
      }
    }
  }
}
```

### Stream Response Format

```json
data: {"id":"gen-...","choices":[{"delta":{"content":"The"}}]}
data: {"id":"gen-...","choices":[{"delta":{"content":" capital"}}]}
data: {"id":"gen-...","choices":[{"delta":{"content":" of"}}]}
data: [DONE]
```

## Models

### Popular Models

| Model | Provider | Description | Context | Cost (per 1M tokens) |
|-------|----------|-------------|---------|---------------------|
| gpt-4o | OpenAI | Latest GPT-4 Omni | 128k | $5 / $15 |
| gpt-4-turbo | OpenAI | GPT-4 Turbo | 128k | $10 / $30 |
| gpt-3.5-turbo | OpenAI | Fast & cheap | 16k | $0.50 / $1.50 |
| claude-3-opus | Anthropic | Most capable | 200k | $15 / $75 |
| claude-3-sonnet | Anthropic | Balanced | 200k | $3 / $15 |
| claude-3-haiku | Anthropic | Fast & cheap | 200k | $0.25 / $1.25 |
| gemini-pro | Google | Google's best | 32k | $0.50 / $1.50 |
| llama-3-70b | Meta | Open source | 8k | $0.88 / $0.88 |

### Model Format

Models are specified as `provider/model-name`:

```javascript
{
  model: 'openai/gpt-4o'
  // or
  model: 'anthropic/claude-3-opus'
  // or
  model: 'google/gemini-pro'
}
```

### List All Models

```javascript
const response = await fetch('https://openrouter.ai/api/v1/models', {
  headers: {
    'Authorization': `Bearer ${API_KEY}`,
  },
});

const models = await response.json();
console.log(models.data);  // Array of model objects
```

## Best Practices

### 1. Cost Optimization

```javascript
// Use cheaper models for simple tasks
const simpleTask = {
  model: 'openai/gpt-3.5-turbo',  // Cheaper
  messages: [{role: 'user', content: 'Summarize this text'}],
};

// Use powerful models for complex tasks
const complexTask = {
  model: 'openai/gpt-4o',  // More expensive but better
  messages: [{role: 'user', content: 'Write production code'}],
};
```

### 2. Implement Retry Logic

```javascript
async function callWithRetry(requestBody, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url, options);
      if (response.ok) return await response.json();
      
      if (response.status === 429) {
        // Rate limited, wait and retry
        await new Promise(r => setTimeout(r, 2000 * (i + 1)));
        continue;
      }
      
      throw new Error(`HTTP ${response.status}`);
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await new Promise(r => setTimeout(r, 1000 * (i + 1)));
    }
  }
}
```

### 3. Set Timeouts

```javascript
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 30000);  // 30 seconds

try {
  const response = await fetch(url, {
    signal: controller.signal,
    ...options
  });
} finally {
  clearTimeout(timeout);
}
```

### 4. Monitor Token Usage

```javascript
const response = await callAPI(request);

console.log('Tokens used:', response.usage.total_tokens);
console.log('Approximate cost:', 
  (response.usage.prompt_tokens * 0.005 + 
   response.usage.completion_tokens * 0.015) / 1000
);
```

### 5. Use System Messages Effectively

```javascript
{
  messages: [
    {
      role: 'system',
      content: 'You are a helpful assistant. Keep responses under 100 words.'
    },
    {
      role: 'user',
      content: 'Explain quantum computing'
    }
  ],
  max_tokens: 150  // Enforce limit
}
```

### 6. Handle Long Content

```javascript
function truncateText(text, maxTokens = 4000) {
  // Rough estimate: 1 token ≈ 4 characters
  const maxChars = maxTokens * 4;
  if (text.length > maxChars) {
    return text.slice(0, maxChars) + '...';
  }
  return text;
}
```

## Code Examples

### Lua (for KOReader)

```lua
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")

local function callOpenRouter(api_key, messages, model)
    model = model or "openai/gpt-3.5-turbo"
    
    local request_body = json.encode({
        model = model,
        messages = messages,
        temperature = 0.7,
        max_tokens = 500,
    })
    
    local response_body = {}
    local res, code, headers, status = http.request{
        url = "https://openrouter.ai/api/v1/chat/completions",
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#request_body),
            ["Authorization"] = "Bearer " .. api_key,
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body),
    }
    
    if code ~= 200 then
        return nil, "HTTP error: " .. tostring(code)
    end
    
    local response_text = table.concat(response_body)
    local ok, response = pcall(json.decode, response_text)
    
    if not ok then
        return nil, "JSON decode error: " .. tostring(response)
    end
    
    if response.error then
        return nil, "API error: " .. response.error.message
    end
    
    return response.choices[1].message.content
end

-- Usage
local messages = {
    {role = "system", content = "You are a helpful assistant."},
    {role = "user", content = "Summarize this chapter in 3 sentences."}
}

local content, err = callOpenRouter("sk-or-v1-...", messages)
if content then
    print("Response:", content)
else
    print("Error:", err)
end
```

### Python

```python
import requests

def call_openrouter(api_key, messages, model="openai/gpt-3.5-turbo"):
    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json={
            "model": model,
            "messages": messages,
        }
    )
    
    response.raise_for_status()
    return response.json()["choices"][0]["message"]["content"]

# Usage
messages = [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"}
]

content = call_openrouter("sk-or-v1-...", messages)
print(content)
```

### JavaScript/TypeScript

```typescript
async function callOpenRouter(
  apiKey: string,
  messages: Array<{role: string; content: string}>,
  model: string = 'openai/gpt-3.5-turbo'
): Promise<string> {
  const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      messages,
    }),
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${await response.text()}`);
  }

  const data = await response.json();
  return data.choices[0].message.content;
}

// Usage
const messages = [
  {role: 'system', content: 'You are a helpful assistant.'},
  {role: 'user', content: 'Hello!'}
];

const content = await callOpenRouter('sk-or-v1-...', messages);
console.log(content);
```

## Rate Limits

- Rate limits vary by model and provider
- Check your account dashboard for current limits
- Implement exponential backoff for 429 errors
- Consider caching responses when possible

## Pricing

- Pricing is per 1 million tokens
- Input tokens (prompt) and output tokens (completion) priced separately
- Check [https://openrouter.ai/models](https://openrouter.ai/models) for current pricing
- Monitor usage in your dashboard

## Support

- **Documentation**: [https://openrouter.ai/docs](https://openrouter.ai/docs)
- **Discord**: [https://discord.gg/openrouter](https://discord.gg/openrouter)
- **Email**: support@openrouter.ai
- **Status Page**: [https://status.openrouter.ai](https://status.openrouter.ai)

---

**Ready to build with AI!** 🤖
