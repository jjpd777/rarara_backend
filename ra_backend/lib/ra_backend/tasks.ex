defmodule RaBackend.Tasks do
  @moduledoc """
  The Tasks context for managing background task execution.
  """

  import Ecto.Query, warn: false
  alias RaBackend.Repo
  alias RaBackend.Tasks.Task
  alias Ecto.Multi

  @dev_user_id "11111111-1111-1111-1111-111111111111"

  @doc """
  Creates a task with hardcoded development user.
  """
  def create_task(attrs \\ %{}) do
    attrs
    |> Map.put(:user_id, @dev_user_id)
    |> then(&%Task{} |> Task.changeset(&1) |> Repo.insert())
  end

  @doc """
  Gets a single task.
  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Updates a task.
  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates task progress and broadcasts to WebSocket subscribers.
  Leverages Ecto.Multi for atomic database + PubSub operations.
  """
  def update_task_progress(task_id, progress) do
    Multi.new()
    |> Multi.update(:task, fn _ ->
      get_task!(task_id)
      |> Task.changeset(%{
        progress: progress,
        status: determine_status(progress)
      })
    end)
    |> Multi.run(:broadcast, fn _, %{task: task} ->
      Phoenix.PubSub.broadcast(
        RaBackend.PubSub,
        "task:#{task_id}",
        {:progress_update, %{
          task_id: task_id,
          progress: progress,
          status: task.status,
          timestamp: DateTime.utc_now()
        }}
      )
      {:ok, task}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{task: task}} -> {:ok, task}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  defp determine_status(progress) when progress >= 1.0, do: :completed
  defp determine_status(_), do: :processing

  @doc """
  Returns the hardcoded development user ID.
  """
  def dev_user_id, do: @dev_user_id
end
