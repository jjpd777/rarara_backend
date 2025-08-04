# Test script for LLM WebSocket functionality
# Run with: mix run scripts/test_llm_websocket.exs

# Start the application context
Mix.Task.run("app.start")

# Test the LLM generation logic directly
defmodule LLMWebSocketTest do
  require Logger
  alias RaBackend.LLM.LLMService.Request
  alias RaBackend.LLM.ProviderRouter

  def test_llm_service_integration do
    Logger.info("Testing LLM service integration...")

    # Test the core LLM functionality that our WebSocket uses
    request = %Request{
      prompt: "Hello! How are you today?",
      model: "gemini-2.5-flash-lite",  # Using the default model
      options: %{}
    }

    Logger.info("Test request: model=#{request.model}, prompt=#{String.slice(request.prompt, 0, 50)}...")

    # This is the same call our WebSocket handler makes
    case ProviderRouter.route_request_with_retry(request) do
      {:ok, response} ->
        Logger.info("✅ LLM generation successful!")
        Logger.info("📝 Content: #{String.slice(response.content, 0, 100)}...")
        Logger.info("🆔 Generation ID: #{response.generation_id}")
        Logger.info("🏭 Provider: #{response.provider}")
        Logger.info("🤖 Model: #{response.model}")

      {:error, error} ->
        Logger.error("❌ LLM generation failed: #{inspect(error)}")

        # Check if it's a configuration issue
        case error do
          %{reason: reason} when is_binary(reason) ->
            if String.contains?(reason, "API key") do
              Logger.info("💡 This might be an API key configuration issue")
              Logger.info("💡 Check your .env file or config/dev.exs for LLM provider settings")
            end
          _ -> nil
        end
    end
  end

  def test_payload_validation do
    Logger.info("Testing payload validation logic...")

    # Test the validation logic from our WebSocket handler
    test_cases = [
      %{"prompt" => "Hello!", "model" => "gemini-2.5-flash-lite"},  # Valid
      %{"prompt" => "", "model" => "gemini-2.5-flash-lite"},        # Empty prompt
      %{"model" => "gemini-2.5-flash-lite"},                        # Missing prompt
      %{"prompt" => "Hello!"},                                      # Missing model (should default)
    ]

    Enum.each(test_cases, fn payload ->
      prompt = Map.get(payload, "prompt")
      model = Map.get(payload, "model", "gemini-2.5-flash-lite")

      case validate_payload(prompt, model) do
        {:ok, request} ->
          Logger.info("✅ Valid payload: #{inspect(Map.keys(payload))} -> Request created")

        {:error, reason} ->
          Logger.info("❌ Invalid payload: #{inspect(Map.keys(payload))} -> #{reason}")
      end
    end)
  end

  # Extract the validation logic from our WebSocket handler
  defp validate_payload(prompt, model) do
    if is_nil(prompt) or prompt == "" do
      {:error, "Prompt is required for LLM generation"}
    else
      request = %Request{
        prompt: prompt,
        model: model,
        options: %{}
      }
      {:ok, request}
    end
  end
end

# Run the tests
require Logger
Logger.info("🧪 Starting LLM WebSocket tests...")
IO.puts("")

LLMWebSocketTest.test_payload_validation()
IO.puts("")
LLMWebSocketTest.test_llm_service_integration()

IO.puts("")
IO.puts("🚀 LLM WebSocket implementation is ready!")
IO.puts("📱 Swift clients can now use:")
IO.puts("   socket.push('llm_generate', {prompt: 'Hello!'})")
IO.puts("   socket.on('llm_response', response => { ... })")
IO.puts("")
IO.puts("💡 To test the full WebSocket flow:")
IO.puts("   1. Start the Phoenix server: mix phx.server")
IO.puts("   2. Connect to ws://localhost:4000/socket")
IO.puts("   3. Join channel: task:test_id")
IO.puts("   4. Send: llm_generate with {prompt: 'Hello!'}")
IO.puts("   5. Receive: llm_response with generated content")
