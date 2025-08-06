defmodule RaBackendWeb.TaskController do
  @moduledoc """
  Controller for task management API endpoints.
  Leverages Elixir's with statement and pipe operator for clean error handling.
  """

  use RaBackendWeb, :controller

  alias RaBackend.Tasks
  alias RaBackend.Workers.TaskWorker

  require Logger

  @doc """
  Creates a new task and enqueues it for background processing.
  """
  def create(conn, params) do
    Logger.info("Creating new task with params: #{inspect(params)}")

    # Determine task_type from input_data
    task_params = determine_task_params(params)

    # Leverage Elixir's with statement for elegant error handling
    with {:ok, task} <- Tasks.create_task(task_params),
         {:ok, _job} <- enqueue_task_job(task.id) do

      Logger.info("Task created successfully: #{task.id}")

      conn
      |> put_status(:accepted)
      |> json(%{
        success: true,
        data: %{
          task_id: task.id,
          status: task.status,
          progress: task.progress
        },
        message: "Task created and queued for processing"
      })

    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Logger.warning("Task creation failed: #{inspect(changeset.errors)}")

        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: %{
            code: "VALIDATION_ERROR",
            message: "Failed to create task",
            details: transform_changeset_errors(changeset)
          }
        })

      {:error, reason} ->
        Logger.error("Unexpected error creating task: #{inspect(reason)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{
          success: false,
          error: %{
            code: "INTERNAL_ERROR",
            message: "An unexpected error occurred"
          }
        })
    end
  end

  @doc """
  Gets the current status of a task.
  """
  def show(conn, %{"id" => task_id}) do
    Logger.debug("Fetching task status: #{task_id}")

    try do
      task = Tasks.get_task!(task_id)

      conn
      |> json(%{
        success: true,
        data: %{
          task_id: task.id,
          status: task.status,
          progress: task.progress,
          input_data: task.input_data,
          created_at: task.inserted_at,
          updated_at: task.updated_at
        }
      })

    rescue
      Ecto.NoResultsError ->
        Logger.warning("Task not found: #{task_id}")

        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: %{
            code: "NOT_FOUND",
            message: "Task not found"
          }
        })
    end
  end

  # Private helper functions

  defp determine_task_params(params) do
    task_type = case get_in(params, ["input_data", "type"]) do
      "image" -> "image_gen"
      "video" -> "video_gen"
      "text" -> "text_gen"
      _ -> "text_gen"  # Default fallback
    end

    Map.put(params, "task_type", task_type)
  end

  defp enqueue_task_job(task_id) do
    %{task_id: task_id}
    |> TaskWorker.new()
    |> Oban.insert()
  end

  defp transform_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
