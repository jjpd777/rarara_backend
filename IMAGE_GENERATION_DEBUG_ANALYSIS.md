# Image Generation Debug Analysis

## Overview
This document analyzes a dual-path image generation workflow issue discovered through server logs and Swift client logs. The problem involved the API endpoint missing default model assignment, causing task failures.

## System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Swift Client  │    │  Phoenix Server │    │  Replicate API  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## The Problem: Dual-Path Workflow

### Path 1: API Endpoint (BROKEN)
```
Swift Client                    Phoenix Server                 Database
     │                               │                          │
     │ POST /api/tasks               │                          │
     │ {"input_data":                │                          │
     │  {"type":"image",             │                          │
     │   "prompt":"Medieval monk"}}  │                          │
     ├──────────────────────────────►│                          │
     │                               │ determine_task_params()  │
     │                               │ task_type = "image_gen"  │
     │                               │ ❌ NO MODEL ASSIGNED     │
     │                               │                          │
     │                               │ Tasks.create_task()      │
     │                               ├─────────────────────────►│
     │                               │                          │ INSERT task
     │                               │                          │ model: NULL ❌
     │                               │◄─────────────────────────┤
     │ 202 Accepted                  │                          │
     │ task_id: 508b9881...          │                          │
     │◄──────────────────────────────┤                          │
     │                               │                          │
     │                               │ TaskWorker.perform()     │
     │                               │ ModelRegistry.find...    │
     │                               │ ❌ :unsupported_model    │
     │                               │    (model is nil)        │
```

### Path 2: WebSocket Channel (WORKING)
```
Swift Client                    Phoenix Server                 Database
     │                               │                          │
     │ WebSocket: task:508b9881...   │                          │
     ├──────────────────────────────►│ TaskChannel.join()       │
     │                               │                          │
     │ "image_generate" event        │                          │
     │ {"prompt": "Medieval monk",   │                          │
     │  "model": "google/imagen..."}│                          │
     ├──────────────────────────────►│                          │
     │                               │ handle_in("image_gen")   │
     │                               │ model = "google/imagen-  │
     │                               │         4-fast" ✅       │
     │                               │                          │
     │                               │ Tasks.create_task()      │
     │                               ├─────────────────────────►│
     │                               │                          │ INSERT new task
     │                               │                          │ model: "google..." ✅
     │                               │◄─────────────────────────┤
     │                               │                          │
     │                               │ TaskWorker.perform()     │
     │                               │ ✅ SUCCESS               │
```

## Log Analysis

### Server Logs Timeline

```
Timeline: Elixir Server Perspective

[T+0s]   POST /api/tasks - Creates task 508b9881... (NO MODEL)
         ├─ INSERT INTO tasks (...model=NULL...)
         └─ Returns 202 Accepted

[T+0.1s] TaskWorker starts for 508b9881...
         ├─ ModelRegistry.find_provider_by_model(nil)
         └─ ❌ ERROR: :unsupported_model

[T+1s]   Client connects to WebSocket task:508b9881...
         └─ TaskChannel.join() ✅

[T+1.1s] WebSocket "image_generate" event received
         ├─ Creates NEW task 10628cdb... (WITH MODEL)
         ├─ INSERT INTO tasks (...model="google/imagen-4-fast"...)
         └─ Returns success response

[T+1.2s] TaskWorker starts for 10628cdb...
         ├─ Replicate API call
         ├─ Polling for progress (60% → 100%)
         └─ ✅ SUCCESS: Image generated

[T+20s]  Original failed task 508b9881... retries
         └─ ❌ Still fails (model still NULL)
```

### Swift Client Logs Timeline

```
Timeline: Swift Client Perspective

📤 POST /api/tasks → {"input_data":{"type":"image","prompt":"Beautiful Christian Park"}}
📥 202 Response → task_id: "75774c14-9dc8-454c-ad6a-9bf79f6d477e"
📡 Subscribe to → task:75774c14-9dc8-454c-ad6a-9bf79f6d477e

🎨 Send image_generate event → "Beautiful Christian Park"
📨 Receive: status → failed (10%) ❌        [Original API task fails]
📨 Receive: image_response → success ✅     [New WebSocket task created]
📨 Receive: progress → processing (10%) ✅  [New task progressing]
📨 Receive: progress → processing (10%) ✅
📨 Receive: progress → processing (10%) ✅

🗑️ Client cleanup and unsubscribe
```

## The Confusion

The client receives **mixed signals**:
1. **Failure** from the original API-created task (missing model)
2. **Success** from the new WebSocket-created task (with model)

Both tasks share the same channel ID, creating confusion about which task is actually working.

## Root Cause Analysis

### Problem Location
- **File**: `ra_backend/lib/ra_backend_web/controllers/task_controller.ex`
- **Function**: `determine_task_params/1`
- **Issue**: Missing default model assignment for image/video tasks

### Original Broken Code
```elixir
defp determine_task_params(params) do
  task_type = case get_in(params, ["input_data", "type"]) do
    "image" -> "image_gen"
    "video" -> "video_gen"
    "text" -> "text_gen"
    _ -> "text_gen"
  end

  Map.put(params, "task_type", task_type)  # ❌ No model assigned
end
```

### Fixed Code
```elixir
defp determine_task_params(params) do
  task_type = case get_in(params, ["input_data", "type"]) do
    "image" -> "image_gen"
    "video" -> "video_gen"
    "text" -> "text_gen"
    _ -> "text_gen"
  end

  task_params = Map.put(params, "task_type", task_type)
  
  # Add default model for image/video generation
  case task_type do
    "image_gen" -> Map.put(task_params, "model", "google/imagen-4-fast")
    "video_gen" -> Map.put(task_params, "model", "bytedance/seedance-1-pro")
    _ -> task_params
  end
end
```

## Expected Behavior After Fix

### Single-Path Workflow (CLEAN)
```
Swift Client                    Phoenix Server                 Database
     │                               │                          │
     │ POST /api/tasks               │                          │
     │ {"input_data":                │                          │
     │  {"type":"image",             │                          │
     │   "prompt":"Medieval monk"}}  │                          │
     ├──────────────────────────────►│                          │
     │                               │ determine_task_params()  │
     │                               │ task_type = "image_gen"  │
     │                               │ ✅ model = "google/..."  │
     │                               │                          │
     │                               │ Tasks.create_task()      │
     │                               ├─────────────────────────►│
     │                               │                          │ INSERT task
     │                               │                          │ model: "google..." ✅
     │                               │◄─────────────────────────┤
     │ 202 Accepted                  │                          │
     │ task_id: abc123...            │                          │
     │◄──────────────────────────────┤                          │
     │                               │                          │
     │ WebSocket: task:abc123...     │                          │
     ├──────────────────────────────►│ TaskChannel.join()       │
     │                               │                          │
     │                               │ TaskWorker.perform()     │
     │                               │ ✅ SUCCESS               │
     │                               │                          │
     │ Receive: progress updates     │                          │
     │◄──────────────────────────────┤                          │
     │ Receive: final success        │                          │
     │◄──────────────────────────────┤                          │
```

## Impact on Swift Development

### Before Fix (Confusing)
- Client creates task via API → Gets task ID
- Client connects to WebSocket → Receives failure status
- Client sends image_generate → Receives success response
- **Result**: Mixed signals, unclear which task succeeded

### After Fix (Clean)
- Client creates task via API → Gets task ID with proper model
- Client connects to WebSocket → Receives progress updates
- **Result**: Single clear workflow, no confusion

## Recommendations for Swift Team

1. **No Swift code changes required** - this is purely a backend fix
2. **Test the happy path** - API → WebSocket should now work seamlessly
3. **Remove any dual-path workarounds** if they exist in Swift code
4. **Expect consistent behavior** from both API endpoint and WebSocket channel

## Model Registry

The system supports these models:

### Image Generation
- `google/imagen-4-fast` (default)
- `bytedance/seedream-3`

### Video Generation  
- `bytedance/seedance-1-pro` (default)

### Text Generation
- `gpt-4.1`
- `claude-sonnet-4-20250514` 
- `gemini-2.5-flash-lite`

## Testing

To verify the fix:

```bash
# Test API endpoint
curl -X POST https://your-domain/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"input_data":{"type":"image","prompt":"Test image"}}'

# Should return task with model assigned
# Then connect to WebSocket task:TASK_ID
# Should receive clean progress updates without failures
``` 