# rarara_backend

---

## AI Generation API – Quickstart for iOS/Swift

### Overview

This API provides a unified endpoint for generating text using multiple LLM providers (OpenAI, Anthropic, Gemini, etc.). You send a prompt and model name, and receive a structured response with the generated content and metadata.

---

### Endpoint

**POST** `/api/llm/generate`

---

### Request Format

Send a JSON body with the following fields:

| Field      | Type     | Required | Description                                 |
|------------|----------|----------|---------------------------------------------|
| model      | String   | Yes      | Model identifier (see below for options)    |
| prompt     | String   | Yes      | The text prompt to send to the LLM          |
| options    | Object   | No       | Generation options (see below)              |

**Example:**
```json
{
  "model": "gpt-4.1",
  "prompt": "Write a short poem about the sea.",
  "options": {
    "max_tokens": 50,
    "temperature": 0.7
  }
}
```

#### Options

- `max_tokens` (Int): Maximum tokens to generate (provider-specific minimums may apply)
- `temperature` (Float): Controls randomness (0.0 = deterministic, 1.0 = creative)
- (Other options like `top_p`, `top_k` may be supported by some models)

---

### Supported Models

Call `GET /api/llm/models` to list available models. Example models:

- `"gpt-4.1"` (OpenAI)
- `"gpt-4.1-mini"` (OpenAI)
- `"claude-sonnet-4-20250514"` (Anthropic)
- `"gemini-2.5-flash-lite"` (Google)
- `"gemini-2.5-flash"` (Google)

---

### Response Format

A successful response (`200 OK`) returns:

```json
{
  "success": true,
  "data": {
    "content": "The generated text here.",
    "generationId": "req_ABC123..."
  },
  "metadata": {
    "model": "gpt-4.1",
    "provider": "openai",
    "tokens": {
      "input": 12,
      "output": 50,
      "total": 62,
      "maxRequested": 50
    },
    "config": {
      "temperature": 0.7,
      "finishReason": "stop"
    },
    "timing": {
      "responseMs": 1234
    },
    "request": {
      "attemptNumber": 1,
      "retryCount": 0,
      "timestamp": "2024-07-15T12:34:56Z"
    }
  }
}
```

#### Error Response

If the request fails, you’ll get:

```json
{
  "success": false,
  "error": {
    "code": "MODEL_NOT_FOUND",
    "message": "The requested model is not supported",
    "details": {
      "requestedModel": "bad-model",
      "availableModels": ["gpt-4.1", ...]
    }
  },
  "metadata": {
    "requestId": "req_...",
    "timestamp": "2024-07-15T12:34:56Z",
    "attemptedModel": "bad-model"
  }
}
```

---

### Swift Usage Example

```swift
let url = URL(string: "http://your-server/api/llm/generate")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let body: [String: Any] = [
    "model": "gpt-4.1",
    "prompt": "Write a short poem about the sea.",
    "options": [
        "max_tokens": 50,
        "temperature": 0.7
    ]
]
request.httpBody = try! JSONSerialization.data(withJSONObject: body)

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    guard let data = data else { return }
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        print(json)
    }
}
task.resume()
```

---

### Notes

- The `"model"` field is required and must match one of the supported models.
- The `"provider"` field is ignored; routing is based on the `"model"` prefix.
- Provider-specific minimums for `max_tokens` may override your request for very low values.
- All responses include a `"generationId"` for tracing/debugging.
- Error codes are standardized for easy handling in your app.

---

**For more details, see the `/api/llm/models` endpoint or contact the backend team.**