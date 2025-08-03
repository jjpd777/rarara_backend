defmodule RaBackendWeb.TaskChannel do
  @moduledoc """
  Phoenix Channel for real-time task progress updates.
  Leverages PubSub for decoupled communication with background workers.
  """

  use RaBackendWeb, :channel

  alias RaBackend.Tasks

  require Logger

  @impl true
  def join("task:" <> task_id, _payload, socket) do
    Logger.info("Client joining task channel: #{task_id}")

    # Subscribe to PubSub topic for this specific task
    Phoenix.PubSub.subscribe(RaBackend.PubSub, "task:#{task_id}")

    # Send current task status immediately upon joining
    try do
      task = Tasks.get_task!(task_id)

      push(socket, "status", %{
        task_id: task_id,
        status: task.status,
        progress: task.progress,
        message: "Connected to task #{task_id}",
        timestamp: DateTime.utc_now()
      })

      Logger.debug("Client connected to task #{task_id}, current progress: #{task.progress}")
      {:ok, assign(socket, :task_id, task_id)}

    rescue
      Ecto.NoResultsError ->
        Logger.warning("Client attempted to join non-existent task: #{task_id}")
        {:error, %{reason: "Task not found"}}
    end
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
end
