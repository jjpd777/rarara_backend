defmodule RaBackendWeb.TaskChannel do
  @moduledoc """
  Phoenix Channel for real-time task progress updates and LLM generations.
  Leverages PubSub for decoupled communication with background workers.
  """

  use RaBackendWeb, :channel

  alias RaBackend.Tasks
  alias RaBackend.LLM.LLMService.Request
  alias RaBackend.LLM.ProviderRouter

  require Logger

  @impl true
  def join("task:" <> task_id, _payload, socket) do
    Logger.info("Client joining task channel: #{task_id}")

    # Subscribe to PubSub topic for this specific task
    Phoenix.PubSub.subscribe(RaBackend.PubSub, "task:#{task_id}")

    # Check if this is an LLM chat channel (doesn't need a real Task record)
    if is_llm_channel?(task_id) do
      Logger.info("Joined LLM chat channel: #{task_id}")
      {:ok, assign(socket, :task_id, task_id)}
    else
      # Verify actual task exists before allowing join
      try do
        task = Tasks.get_task!(task_id)

        # Send message to self to push initial status after join completes
        send(self(), :after_join)

        Logger.debug("Client connected to task #{task_id}, current progress: #{task.progress}")
        {:ok, assign(socket, :task_id, task_id)}

      rescue
        Ecto.NoResultsError ->
          Logger.warning("Client attempted to join non-existent task: #{task_id}")
          {:error, %{reason: "Task not found"}}
      end
    end
  end

  # Helper function to identify LLM chat channels
  defp is_llm_channel?(task_id) do
    String.starts_with?(task_id, "llm_") or
    String.starts_with?(task_id, "chat_") or
    String.starts_with?(task_id, "swift_")
  end

  @impl true
  def handle_info(:after_join, socket) do
    task_id = socket.assigns.task_id

    # Only send initial status for real tasks, not LLM chat channels
    if is_llm_channel?(task_id) do
      Logger.debug("LLM chat channel #{task_id} ready for messages")
    else
      # Now we can safely push the initial status for real tasks
      try do
        task = Tasks.get_task!(task_id)

        push(socket, "status", %{
          task_id: task_id,
          status: task.status,
          progress: task.progress,
          message: "Connected to task #{task_id}",
          timestamp: DateTime.utc_now()
        })

      rescue
        Ecto.NoResultsError ->
          Logger.warning("Task #{task_id} was deleted after join")
      end
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:progress_update, payload}, socket) do
    # Leverage pattern matching for clean message handling
    Logger.debug("Broadcasting progress update: #{inspect(payload)}")
    push(socket, "progress", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_in("ping", payload, socket) do
    # Simple ping-pong for connection testing
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("llm_generate", payload, socket) do
    Logger.info("LLM generation request received: #{inspect(Map.keys(payload))}")

    # Extract parameters with defaults
    prompt = Map.get(payload, "prompt")
    model = Map.get(payload, "model", "gemini-2.5-flash-lite")  # Default to Gemini Flash Lite
    options = Map.get(payload, "options", %{})
    request_id = Map.get(payload, "request_id")

    # Validate required prompt
    if is_nil(prompt) or prompt == "" do
      push(socket, "llm_response", %{
        success: false,
        error: %{
          code: "missing_prompt",
          message: "Prompt is required for LLM generation"
        },
        timestamp: DateTime.utc_now(),
        request_id: request_id
      })
      {:noreply, socket}
    else
      # Create LLM request using existing infrastructure
      request = %Request{
        prompt: prompt,
        model: model,
        options: options
      }

      Logger.debug("Executing LLM generation: model=#{model}, prompt_length=#{String.length(prompt)}")

      # Execute directly using existing LLM service with retry logic
      case ProviderRouter.route_request_with_retry(request) do
        {:ok, response} ->
          Logger.info("LLM generation successful: id=#{response.generation_id}, model=#{response.model}")

          push(socket, "llm_response", %{
            success: true,
            content: response.content,
            generation_id: response.generation_id,
            model: response.model,
            provider: to_string(response.provider),
            timestamp: DateTime.utc_now(),
            request_id: request_id
          })

        {:error, error} ->
          Logger.error("LLM generation failed: #{inspect(error)}")

          push(socket, "llm_response", %{
            success: false,
            error: %{
              code: "generation_failed",
              message: "Failed to generate response",
              details: inspect(error)
            },
            timestamp: DateTime.utc_now(),
            request_id: request_id
          })
      end

      {:noreply, socket}
    end
  end
end
