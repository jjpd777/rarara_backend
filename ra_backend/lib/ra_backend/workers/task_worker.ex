defmodule RaBackend.Workers.TaskWorker do
  @moduledoc """
  Oban worker for processing tasks with real-time progress updates.
  Supports both text generation (LLM) and image generation (Replicate).
  Leverages Elixir's process isolation and functional programming.
  """

  use Oban.Worker, max_attempts: 3

  alias RaBackend.Tasks
  alias RaBackend.ModelRegistry
  alias RaBackend.LLM.LLMService.Request
  alias RaBackend.LLM.ProviderRouter

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"task_id" => task_id}}) do
    Logger.info("Starting task worker for task_id: #{task_id}")

    try do
      task = Tasks.get_task!(task_id)

      # Update status to processing
      {:ok, _task} = Tasks.update_task_progress(task_id, 0.1)

      # Dispatch based on task type - only allow image/video generation in Oban
      result = case task.task_type do
        :image_gen -> process_image_generation(task)
        :video_gen -> process_video_generation(task)
        other_type ->
          Logger.error("Task type #{other_type} not allowed in Oban worker")
          {:error, "Task type #{other_type} disallowed for Oban processing"}
      end

      case result do
        {:ok, result_data} ->
          # Update task with final result and broadcast completion with result_data
          case Tasks.update_task_progress(task_id, 1.0, result_data) do
            {:ok, _task} ->
              Logger.info("Task #{task_id} completed successfully")
              :ok
            {:error, reason} ->
              Logger.error("Failed to complete task #{task_id}: #{inspect(reason)}")
              {:error, reason}
          end

        {:error, reason} ->
          # Update task as failed and broadcast failure with error_data
          error_data = %{error: inspect(reason)}
          case Tasks.update_task_failed(task_id, error_data) do
            {:ok, _task} ->
              Logger.error("Task #{task_id} failed: #{inspect(reason)}")
              {:error, reason}
            {:error, error} ->
              Logger.error("Failed to update failed task #{task_id}: #{inspect(error)}")
              {:error, error}
          end
      end

    rescue
      error ->
        Logger.error("Task worker error for #{task_id}: #{inspect(error)}")
        {:error, error}
    end
  end

  defp process_text_generation(task) do
    # Create LLM request from task data
    request = %Request{
      prompt: task.input_data["prompt"],
      model: task.model,
      options: Map.get(task.input_data, "options", %{})
    }

    # Update progress
    Tasks.update_task_progress(task.id, 0.5)

    # Generate text using existing LLM infrastructure
    case ProviderRouter.route_request_with_retry(request) do
      {:ok, response} ->
        Tasks.update_task_progress(task.id, 0.9)
        {:ok, %{
          content: response.content,
          generation_id: response.generation_id,
          model: response.model,
          provider: to_string(response.provider)
        }}

      {:error, error} ->
        {:error, error}
    end
  end

  defp process_image_generation(task) do
    # Update progress - worker started
    Tasks.update_task_progress(task.id, 0.1)

    # Find provider for the model
    case ModelRegistry.find_provider_by_model(task.model) do
      {:ok, provider} ->
        Logger.info("Starting image generation for task #{task.id} with model #{task.model}")

        # Create progress callback function
        progress_callback = fn task_id, progress ->
          Tasks.update_task_progress(task_id, progress)
          Logger.debug("Updated task #{task_id} progress to #{progress}")
        end

        # Generate image with real-time polling
        params = %{
          model: task.model,
          input: task.input_data,
          wait: :poll,  # Use polling mode for real-time progress
          task_id: task.id,
          progress_callback: progress_callback
        }

        case provider.generate_media(params) do
          {:ok, response} ->
            Logger.info("Image generation completed for task #{task.id}")
            {:ok, %{
              image_url: response["output"],
              prediction_id: response["id"],
              model: task.model,
              provider: "Replicate",
              status: response["status"],
              created_at: response["created_at"],
              completed_at: response["completed_at"]
            }}

          {:error, error} ->
            Logger.error("Image generation failed for task #{task.id}: #{inspect(error)}")
            {:error, error}
        end

      {:error, reason} ->
        Logger.error("Provider lookup failed for task #{task.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp process_video_generation(task) do
    # Update progress - worker started
    Tasks.update_task_progress(task.id, 0.1)

    # Find provider for the model
    case ModelRegistry.find_provider_by_model(task.model) do
      {:ok, provider} ->
        Logger.info("Starting video generation for task #{task.id} with model #{task.model}")

        # Create progress callback function
        progress_callback = fn task_id, progress ->
          Tasks.update_task_progress(task_id, progress)
          Logger.debug("Updated task #{task_id} progress to #{progress}")
        end

        # Generate video with real-time polling
        params = %{
          model: task.model,
          input: task.input_data,
          wait: :poll,  # Use polling mode for real-time progress
          task_id: task.id,
          progress_callback: progress_callback
        }

        case provider.generate_media(params) do
          {:ok, response} ->
            Logger.info("Video generation completed for task #{task.id}")
            {:ok, %{
              video_url: response["output"],
              prediction_id: response["id"],
              model: task.model,
              provider: "Replicate",
              status: response["status"],
              created_at: response["created_at"],
              completed_at: response["completed_at"]
            }}

          {:error, error} ->
            Logger.error("Video generation failed for task #{task.id}: #{inspect(error)}")
            {:error, error}
        end

      {:error, reason} ->
        Logger.error("Provider lookup failed for task #{task.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
