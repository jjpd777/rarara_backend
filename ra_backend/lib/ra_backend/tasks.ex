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
  Creates a task. If no user_id is provided, uses the development user.
  """
  def create_task(attrs \\ %{}) do
    attrs_with_user =
      case Map.get(attrs, "user_id") do
        nil -> Map.put(attrs, "user_id", @dev_user_id)
        _ -> attrs
      end

    attrs_with_user
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
    update_task_progress(task_id, progress, nil)
  end

  @doc """
  Updates task progress with optional result_data and broadcasts to WebSocket subscribers.
  When result_data is provided and progress indicates completion, includes it in broadcast.
  """
  def update_task_progress(task_id, progress, result_data) do
    status = determine_status(progress)

    # Build changeset attributes conditionally
    changeset_attrs = %{progress: progress, status: status}
    changeset_attrs =
      if result_data,
        do: Map.put(changeset_attrs, :result_data, result_data),
        else: changeset_attrs

    Multi.new()
    |> Multi.update(:task, fn _ ->
      get_task!(task_id)
      |> Task.changeset(changeset_attrs)
    end)
    |> Multi.run(:broadcast, fn _, %{task: task} ->
      broadcast_progress_update(task_id, progress, status, result_data)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{task: task}} -> {:ok, task}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  defp determine_status(progress) when progress >= 1.0, do: :completed
  defp determine_status(progress) when progress <= 0.0, do: :processing  # Keep as processing for normal 0 progress
  defp determine_status(_), do: :processing

  @doc """
  Updates a task as failed with error data and broadcasts to WebSocket subscribers.
  """
  def update_task_failed(task_id, error_data) do
    Multi.new()
    |> Multi.update(:task, fn _ ->
      get_task!(task_id)
      |> Task.changeset(%{
        status: :failed,
        result_data: error_data
      })
    end)
    |> Multi.run(:broadcast, fn _, %{task: _task} ->
      broadcast_progress_update(task_id, 0.0, :failed, error_data)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{task: task}} -> {:ok, task}
      {:error, _failed_operation, failed_value, _changes_so_far} -> {:error, failed_value}
    end
  end

  # Private function to handle broadcasting with proper payload construction
  defp broadcast_progress_update(task_id, progress, status, result_data) do
    base_payload = %{
      task_id: task_id,
      progress: progress,
      status: status,
      timestamp: DateTime.utc_now()
    }

    # Pattern match on completion with result_data for clean payload building
    payload = case {status, result_data} do
      {:completed, data} when not is_nil(data) ->
        Map.put(base_payload, :result_data, data)
      {:failed, data} when not is_nil(data) ->
        Map.put(base_payload, :error_data, data)
      _ ->
        base_payload
    end

    Phoenix.PubSub.broadcast(
      RaBackend.PubSub,
      "task:#{task_id}",
      {:progress_update, payload}
    )

    {:ok, :broadcasted}
  end

  @doc """
  Returns the hardcoded development user ID.
  """
  def dev_user_id, do: @dev_user_id
end
