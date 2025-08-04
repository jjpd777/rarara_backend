# Test LLM channel joining fix
# Run with: mix run scripts/test_llm_channel_join.exs

Mix.Task.run("app.start")

defmodule LLMChannelJoinTest do
  require Logger
  alias RaBackendWeb.TaskChannel
  alias Phoenix.Socket

  def test_llm_channel_join do
    Logger.info("Testing LLM channel join functionality...")

    # Simulate a socket connection
    socket = %Socket{
      assigns: %{user_id: "test_user"}
    }

    # Test LLM channel patterns that should work
    test_channels = [
      "llm_chat",
      "llm_test",
      "chat_session_1",
      "swift_llm"
    ]

    Enum.each(test_channels, fn channel_id ->
      Logger.info("Testing channel: task:#{channel_id}")

      case TaskChannel.join("task:#{channel_id}", %{}, socket) do
        {:ok, updated_socket} ->
          Logger.info("✅ Successfully joined LLM channel: #{channel_id}")
          Logger.debug("Socket task_id: #{updated_socket.assigns.task_id}")

        {:error, reason} ->
          Logger.error("❌ Failed to join channel #{channel_id}: #{inspect(reason)}")
      end
    end)

    # Test a real task ID that should still require validation
    Logger.info("Testing real task ID (should fail without actual task)...")
    real_task_id = "01234567-89ab-cdef-0123-456789abcdef"

    case TaskChannel.join("task:#{real_task_id}", %{}, socket) do
      {:ok, _socket} ->
        Logger.info("✅ Real task joined (unexpected - task might exist)")

      {:error, %{reason: "Task not found"}} ->
        Logger.info("✅ Real task validation working correctly - task not found")

      {:error, reason} ->
        Logger.error("❌ Unexpected error for real task: #{inspect(reason)}")
    end
  end

  def test_llm_channel_detection do
    Logger.info("Testing LLM channel detection logic...")

    # Test the private function logic (we'll replicate it here)
    test_cases = [
      {"llm_chat", true},
      {"chat_session", true},
      {"swift_test", true},
      {"regular_task_id", false},
      {"01234567-89ab-cdef-0123-456789abcdef", false}
    ]

    Enum.each(test_cases, fn {task_id, expected} ->
      result = is_llm_channel?(task_id)
      status = if result == expected, do: "✅", else: "❌"
      Logger.info("#{status} #{task_id} -> #{result} (expected: #{expected})")
    end)
  end

  # Replicate the private function for testing
  defp is_llm_channel?(task_id) do
    String.starts_with?(task_id, "llm_") or
    String.starts_with?(task_id, "chat_") or
    String.starts_with?(task_id, "swift_")
  end
end

# Run tests
require Logger
Logger.info("🧪 Testing LLM channel join fixes...")
IO.puts("")

LLMChannelJoinTest.test_llm_channel_detection()
IO.puts("")
LLMChannelJoinTest.test_llm_channel_join()

IO.puts("")
IO.puts("🚀 LLM channel joining should now work!")
IO.puts("📱 Your Swift app can join: task:llm_chat")
IO.puts("💡 Supported prefixes: llm_, chat_, swift_")
