# Swift Integration Example (SwiftPhoenix)

## Setup WebSocket Connection

```swift
import SwiftPhoenixClient

class LLMService {
    private var socket: Socket!
    private var channel: Channel!
    
    init() {
        // Connect to your Phoenix WebSocket endpoint
        socket = Socket("ws://localhost:4000/socket", transport: URLSessionTransport.self)
        
        setupSocketEventHandlers()
        socket.connect()
    }
    
    private func setupSocketEventHandlers() {
        socket.onOpen { [weak self] in
            print("✅ Connected to Phoenix WebSocket")
            self?.joinChannel()
        }
        
        socket.onError { error in
            print("❌ WebSocket error: \(error.localizedDescription)")
        }
        
        socket.onClose { code in
            print("❌ WebSocket closed with code: \(code)")
        }
    }
    
    private func joinChannel() {
        // Join a task channel (you can use any task ID)
        channel = socket.channel("task:swift_llm")
        
        channel.join()
            .receive("ok") { _ in
                print("✅ Joined task channel")
            }
            .receive("error") { error in
                print("❌ Failed to join channel: \(error)")
            }
        
        setupChannelEventHandlers()
    }
    
    private func setupChannelEventHandlers() {
        // Handle LLM responses
        channel.on("llm_response") { [weak self] message in
            self?.handleLLMResponse(message)
        }
    }
}
```

## Simple Text Generation

```swift
extension LLMService {
    
    // Simple generation with default model (gemini-2.5-flash-lite)
    func generateText(_ prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let channel = channel else {
            completion(.failure(NSError(domain: "LLMError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Channel not connected"])))
            return
        }
        
        let payload: [String: Any] = [
            "prompt": prompt
            // model defaults to "gemini-2.5-flash-lite" on backend
        ]
        
        // Store completion for this request
        pendingCompletions[prompt] = completion
        
        // Send message via Phoenix channel
        channel.push("llm_generate", payload)
    }
    
    // Generation with specific model
    func generateText(_ prompt: String, model: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let channel = channel else {
            completion(.failure(NSError(domain: "LLMError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Channel not connected"])))
            return
        }
        
        let payload: [String: Any] = [
            "prompt": prompt,
            "model": model
        ]
        
        pendingCompletions[prompt] = completion
        channel.push("llm_generate", payload)
    }
    
    // Generation with options
    func generateText(_ prompt: String, options: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        guard let channel = channel else {
            completion(.failure(NSError(domain: "LLMError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Channel not connected"])))
            return
        }
        
        let payload: [String: Any] = [
            "prompt": prompt,
            "options": options
        ]
        
        pendingCompletions[prompt] = completion
        channel.push("llm_generate", payload)
    }
}
```

## Response Handling

```swift
extension LLMService {
    private var pendingCompletions: [String: (Result<String, Error>) -> Void] = [:]
    
    private func handleLLMResponse(_ message: Message) {
        guard let responseData = message.payload else { return }
        
        if let success = responseData["success"] as? Bool, success {
            // Success case
            if let content = responseData["content"] as? String {
                let generationId = responseData["generation_id"] as? String
                let model = responseData["model"] as? String
                let provider = responseData["provider"] as? String
                
                print("✅ Generated text: \(content)")
                print("📊 Model: \(model ?? "unknown"), Provider: \(provider ?? "unknown")")
                
                // Find and call completion
                // In a real app, you'd match by generation_id or request_id
                if let completion = pendingCompletions.values.first {
                    completion(.success(content))
                }
            }
        } else {
            // Error case
            if let error = responseData["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ Generation failed: \(message)")
                
                let nsError = NSError(domain: "LLMError", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: message
                ])
                
                if let completion = pendingCompletions.values.first {
                    completion(.failure(nsError))
                }
            }
        }
        
        // Clear completions (in real app, match by ID)
        pendingCompletions.removeAll()
    }
}
```

## Usage in Swift App

```swift
class ChatViewController: UIViewController {
    let llmService = LLMService()
    
    func sendMessage(_ prompt: String) {
        // Show loading indicator
        showLoading()
        
        // Generate response using default model
        llmService.generateText(prompt) { [weak self] result in
            DispatchQueue.main.async {
                self?.hideLoading()
                
                switch result {
                case .success(let content):
                    self?.displayMessage(content)
                    
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }
    
    func sendMessageWithCustomModel(_ prompt: String) {
        llmService.generateText(prompt, model: "gpt-4") { result in
            // Handle result...
        }
    }
}
```

## Key Benefits

1. **Simple API**: Just `channel.push("llm_generate", {prompt})` 
2. **Default Model**: Automatically uses `gemini-2.5-flash-lite`
3. **Real-time**: Instant response via Phoenix WebSocket
4. **Error Handling**: Clear success/error responses
5. **Reuses Infrastructure**: Leverages existing LLM service with retries
6. **Low Latency**: Direct execution, no queue overhead
7. **Phoenix Native**: Uses proper Phoenix channels, not Socket.IO

## Phoenix Channel Events

| Event | Direction | Purpose |
|-------|-----------|---------|
| `llm_generate` | Swift → Server | Request text generation |
| `llm_response` | Server → Swift | Generation result/error |

## SwiftPhoenix Setup

Add to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/davidstump/SwiftPhoenixClient.git", from: "5.0.0")
]
```

## Payload Examples

**Request:**
```json
{
  "prompt": "Hello, how are you?",
  "model": "gemini-2.5-flash-lite",  // optional, defaults to flash-lite
  "options": {                       // optional
    "temperature": 0.7,
    "max_tokens": 150
  }
}
```

**Success Response:**
```json
{
  "success": true,
  "content": "Hello! I'm doing well, thank you for asking...",
  "generation_id": "req_a1b2c3d4e5f6",
  "model": "gemini-2.5-flash-lite",
  "provider": "Elixir.RaBackend.LLM.Providers.Gemini",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": {
    "code": "generation_failed",
    "message": "Failed to generate response",
    "details": "HTTP 429: Rate limit exceeded"
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
``` 