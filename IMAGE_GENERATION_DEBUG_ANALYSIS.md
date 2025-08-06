# Image Generation Flow (with Result Data)

## System Architecture

```
┌─────────────────┐    ┌────────────────────┐    ┌─────────────────┐
│   Swift Client  │    │   Phoenix Server   │    │  Replicate API  │
└─────────────────┘    └────────────────────┘    └─────────────────┘
```

---

## End-to-End Flow

### 1. Task Creation (API)

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
     │                               │ model = "google/imagen-4-fast" (default) │
     │                               │                          │
     │                               │ Tasks.create_task()      │
     │                               ├─────────────────────────►│
     │                               │                          │ INSERT task
     │                               │                          │ model: "google/imagen-4-fast"
     │                               │◄─────────────────────────┤
     │ 202 Accepted                  │                          │
     │ task_id: abc123...            │                          │
     │◄──────────────────────────────┤                          │
```

---

### 2. WebSocket Subscription

```
Swift Client                    Phoenix Server
     │                               │
     │ WebSocket: task:abc123...     │
     ├──────────────────────────────►│ TaskChannel.join()
     │                               │
```

---

### 3. Task Processing & Progress Updates

```
Swift Client                    Phoenix Server                 Replicate API
     │                               │                          │
     │                               │ TaskWorker.perform()     │
     │                               │                          │
     │                               │ 1. Update progress: 0.1  │
     │◄───────── progress {          │                          │
     │      "task_id": "...",        │                          │
     │      "progress": 0.1,         │                          │
     │      "status": "processing",  │                          │
     │      "timestamp": ...         │                          │
     │    }                          │                          │
     │                               │                          │
     │                               │ 2. Call Replicate API    │
     │                               ├─────────────────────────►│
     │                               │                          │
     │                               │ 3. Poll for progress     │
     │◄───────── progress {          │                          │
     │      "task_id": "...",        │                          │
     │      "progress": 0.6,         │                          │
     │      "status": "processing",  │                          │
     │      "timestamp": ...         │                          │
     │    }                          │                          │
```

---

### 4. Task Completion (with Result Data)

```
Swift Client                    Phoenix Server                 Replicate API
     │                               │                          │
     │◄───────── progress {          │                          │
     │      "task_id": "...",        │                          │
     │      "progress": 1.0,         │                          │
     │      "status": "completed",   │                          │
     │      "result_data": {         │                          │
     │        "image_url": "https://replicate.delivery/...",
     │        "model": "google/imagen-4-fast",
     │        "provider": "Replicate",
     │        "prediction_id": "...",
     │        "created_at": "...",
     │        "completed_at": "..."
     │      },
     │      "timestamp": ...
     │    }                          │
     │                               │                          │
```

---

### 5. Task Failure (if any)

```
Swift Client                    Phoenix Server
     │                               │
     │◄───────── progress {          │
     │      "task_id": "...",        │
     │      "progress": 0.0,         │
     │      "status": "failed",      │
     │      "error_data": {          │
     │        "error": "..."         │
     │      },                       │
     │      "timestamp": ...         │
     │    }                          │
```

---

## Payload Example: Task Completed

```json
{
  "task_id": "abc123...",
  "progress": 1.0,
  "status": "completed",
  "result_data": {
    "image_url": "https://replicate.delivery/...",
    "model": "google/imagen-4-fast",
    "provider": "Replicate",
    "prediction_id": "xyz789...",
    "created_at": "2025-01-...",
    "completed_at": "2025-01-..."
  },
  "timestamp": "2025-01-..."
}
```

## Payload Example: Task Failed

```json
{
  "task_id": "abc123...",
  "progress": 0.0,
  "status": "failed",
  "error_data": {
    "error": "..."
  },
  "timestamp": "2025-01-..."
}
```

---

## Swift Client Guidance

- Listen for `"progress"` events on the WebSocket.
- When `"status": "completed"` and `"result_data"` is present, use the `image_url` and other metadata.
- When `"status": "failed"` and `"error_data"` is present, display the error. 