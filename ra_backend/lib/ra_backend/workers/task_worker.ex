defmodule RaBackend.Workers.TaskWorker do
  @moduledoc """
  Oban worker for processing tasks with simulated progress updates.
  Leverages Elixir's process isolation and functional programming.
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  alias RaBackend.Tasks

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_id" => task_id}}) do
    Logger.info("Starting task worker for task_id: #{task_id}")

    task_id
    |> simulate_work_with_progress()
    |> case do
      :ok ->
        Logger.info("Task #{task_id} completed successfully")
        :ok
      {:error, reason} ->
        Logger.error("Task #{task_id} failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp simulate_work_with_progress(task_id) do
    # Leverage Enum.each for functional iteration
    1..5
    |> Enum.each(fn step ->
      # Simulate 2 seconds of work
      Process.sleep(2000)

      # Calculate progress (0.2, 0.4, 0.6, 0.8, 1.0)
      progress = step / 5.0

      # Update task progress with atomic transaction + PubSub
      case Tasks.update_task_progress(task_id, progress) do
        {:ok, _task} ->
          Logger.debug("Task #{task_id} progress updated: #{progress * 100}%")
        {:error, reason} ->
          Logger.warning("Failed to update task #{task_id} progress: #{inspect(reason)}")
      end
    end)

    :ok
  rescue
    error ->
      Logger.error("Task worker error for #{task_id}: #{inspect(error)}")
      {:error, error}
  end
end
