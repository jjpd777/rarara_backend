defmodule RaBackendWeb.TaskController do
  @moduledoc """
  Controller for task management API endpoints.
  Leverages Elixir's with statement and pipe operator for clean error handling.
  """

  use RaBackendWeb, :controller

  alias RaBackend.Tasks
  alias RaBackend.Workers.TaskWorker
  alias RaBackend.Idempotency
  alias RaBackendWeb.Plugs.UserIdPlug

  require Logger

  @doc """
  Creates a new task and enqueues it for background processing.
  Implements idempotency for video generation tasks to prevent duplicates.
  """
  def create(conn, params) do
    Logger.info("Creating new task with params: #{inspect(params)}")

    # Determine task_type from input_data
    task_params = determine_task_params(params)
    user_id = UserIdPlug.current_user_id(conn)
    idempotency_key = get_req_header(conn, "idempotency-key") |> List.first()

    # Handle idempotency only for video generation
    case task_params["task_type"] do
      "video_gen" -> create_video_task_with_idempotency(conn, task_params, user_id, idempotency_key)
      _ -> create_task_without_idempotency(conn, task_params, user_id)
    end
  end

  # Create video task with idempotency logic
  defp create_video_task_with_idempotency(conn, task_params, user_id, idempotency_key) do
    case idempotency_key do
      nil ->
        # No idempotency key provided - proceed normally but log warning
        Logger.warn("Video generation request without idempotency key from user #{user_id}")
        create_task_without_idempotency(conn, task_params, user_id)

      key when is_binary(key) and key != "" ->
        handle_idempotent_video_creation(conn, task_params, user_id, key)

      _ ->
        # Invalid idempotency key
        Logger.warn("Invalid idempotency key from user #{user_id}: #{inspect(idempotency_key)}")
        create_task_without_idempotency(conn, task_params, user_id)
    end
  end

  # Handle idempotent video creation logic
  defp handle_idempotent_video_creation(conn, task_params, user_id, idempotency_key) do
    # Check if this exact request has been processed before
    case Idempotency.find_task_by_key(user_id, idempotency_key) do
      # If YES: Return the original task's data
      {:ok, existing_task} ->
        Logger.info("Returning existing task #{existing_task.id} for idempotency key: #{idempotency_key}")

        conn
        |> put_status(:ok)
        |> json(%{
          success: true,
          data: %{
            task_id: existing_task.id,
            status: existing_task.status,
            progress: existing_task.progress,
            result_data: existing_task.result_data
          },
          message: "Existing task returned (idempotent request)"
        })

      # If NO: Process the new request
      {:error, :not_found} ->
        with {:ok, _idempotency_record} <- Idempotency.store_key(user_id, idempotency_key),
             {:ok, new_task} <- Tasks.create_task(Map.put(task_params, "user_id", user_id)),
             {:ok, _job} <- enqueue_task_job(new_task.id) do
          # 4. Link the key to the new task ID for future lookups
          Idempotency.link_task_to_key(user_id, idempotency_key, new_task.id)

          Logger.info("Created new video task #{new_task.id} with idempotency key: #{idempotency_key}")

          conn
          |> put_status(:created)
          |> json(%{
            success: true,
            data: %{
              task_id: new_task.id,
              status: new_task.status,
              progress: new_task.progress
            },
            message: "Video task created and queued for processing"
          })
        else
          # On failure, clean up the stored key and return an error
          {:error, :already_exists} ->
            # Another request beat us to it - try to find the task again
            case Idempotency.find_task_by_key(user_id, idempotency_key) do
              {:ok, existing_task} ->
                Logger.info("Race condition resolved, returning existing task #{existing_task.id}")

                conn
                |> put_status(:ok)
                |> json(%{
                  success: true,
                  data: %{
                    task_id: existing_task.id,
                    status: existing_task.status,
                    progress: existing_task.progress
                  },
                  message: "Existing task returned (race condition resolved)"
                })

              {:error, _} ->
                Logger.error("Race condition but could not find existing task for key: #{idempotency_key}")
                return_error(conn, :conflict, "RACE_CONDITION", "Duplicate request detected but could not retrieve existing task")
            end

          {:error, %Ecto.Changeset{} = changeset} ->
            Idempotency.delete_key(user_id, idempotency_key)
            Logger.warning("Video task creation failed: #{inspect(changeset.errors)}")
            return_validation_error(conn, changeset)

          {:error, reason} ->
            Idempotency.delete_key(user_id, idempotency_key)
            Logger.error("Unexpected error creating video task: #{inspect(reason)}")
            return_error(conn, :internal_server_error, "INTERNAL_ERROR", "An unexpected error occurred")
        end
    end
  end

  # Create task without idempotency (for non-video tasks)
  defp create_task_without_idempotency(conn, task_params, user_id) do
    # Leverage Elixir's with statement for elegant error handling
    with {:ok, task} <- Tasks.create_task(Map.put(task_params, "user_id", user_id)),
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
        return_validation_error(conn, changeset)

      {:error, reason} ->
        Logger.error("Unexpected error creating task: #{inspect(reason)}")
        return_error(conn, :internal_server_error, "INTERNAL_ERROR", "An unexpected error occurred")
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
          updated_at: task.updated_at,
          result_data: task.result_data
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

    task_params = Map.put(params, "task_type", task_type)

    # Add default model for image/video generation
    case task_type do
      "image_gen" -> Map.put(task_params, "model", "google/imagen-4-fast")
      "video_gen" -> Map.put(task_params, "model", "bytedance/seedance-1-lite")
      _ -> task_params
    end
  end

  defp enqueue_task_job(task_id) do
    %{task_id: task_id}
    |> TaskWorker.new()
    |> Oban.insert()
  end

  # Helper functions for error responses
  defp return_validation_error(conn, changeset) do
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
  end

  defp return_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(%{
      success: false,
      error: %{
        code: code,
        message: message
      }
    })
  end

  defp transform_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
