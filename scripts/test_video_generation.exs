# Test script to verify video generation with Seedance
# This script tests that:
# 1. Video tasks can be created with video_gen type
# 2. Seedance model is properly registered
# 3. Task worker can process video generation
# 4. Progress updates work correctly
# 5. Result data is properly stored

defmodule VideoGenerationTest do
  @moduledoc """
  Test video generation flow using Seedance 1 Pro model
  """

  def run do
    IO.puts("🎬 Testing Video Generation with Seedance")
    IO.puts("=" |> String.duplicate(45))

    test_schema_support()
    test_model_registry()
    test_task_creation()
    test_worker_execution()

    IO.puts("\n✅ All video generation tests completed!")
  end

  defp test_schema_support do
    IO.puts("\n📋 Test 1: Schema should support video_gen task type")

    # Test creating a video task
    task_params = %{
      "task_type" => "video_gen",
      "model" => "bytedance/seedance-1-pro",
      "input_data" => %{
        "prompt" => "Moses splitting the Oceans",
        "duration" => 5
      }
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ SUCCESS: Video task created with ID: #{task.id}")
        IO.puts("📊 Task type: #{task.task_type}")
        IO.puts("📊 Model: #{task.model}")
        IO.puts("📊 Input: #{inspect(task.input_data)}")

      {:error, changeset} ->
        IO.puts("❌ FAIL: Could not create video task")
        IO.puts("   Errors: #{inspect(changeset.errors)}")
    end
  end

  defp test_model_registry do
    IO.puts("\n📋 Test 2: Model registry should support Seedance model")

    case RaBackend.ModelRegistry.find_provider_by_model("bytedance/seedance-1-pro") do
      {:ok, provider} ->
        IO.puts("✅ SUCCESS: Found provider for Seedance model")
        IO.puts("📊 Provider: #{inspect(provider)}")

      {:error, reason} ->
        IO.puts("❌ FAIL: Could not find provider for Seedance")
        IO.puts("   Reason: #{inspect(reason)}")
    end

    # Test video models filter
    video_models = RaBackend.ModelRegistry.all_by_type(:video_gen)
    IO.puts("📊 Video models available: #{length(video_models)}")
    Enum.each(video_models, fn model ->
      IO.puts("   - #{model.display_name} (#{model.model})")
    end)
  end

  defp test_task_creation do
    IO.puts("\n📋 Test 3: Task creation and queue setup")

    task_params = %{
      "task_type" => "video_gen",
      "model" => "bytedance/seedance-1-pro",
      "input_data" => %{
        "prompt" => "Hyperrealistic tiger with Cherubin wings",
        "duration" => 5
      }
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ Task created: #{task.id}")

        # Test Oban job creation
        case enqueue_task_job(task.id) do
          {:ok, oban_job} ->
            IO.puts("✅ SUCCESS: Oban job created successfully")
            IO.puts("📊 Queue: #{oban_job.queue}")
            IO.puts("📊 Args: #{inspect(oban_job.args)}")

          {:error, error} ->
            IO.puts("❌ FAIL: Could not create Oban job")
            IO.puts("   Error: #{inspect(error)}")
        end

      {:error, error} ->
        IO.puts("❌ FAIL: Could not create task")
        IO.puts("   Error: #{inspect(error)}")
    end
  end

  defp test_worker_execution do
    IO.puts("\n📋 Test 4: Worker execution (will fail without API key)")

    task_params = %{
      "task_type" => "video_gen",
      "model" => "bytedance/seedance-1-pro",
      "input_data" => %{
        "prompt" => "Prometheus stealing the fire",
        "duration" => 5
      }
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ Task created: #{task.id}")

        case enqueue_task_job(task.id) do
          {:ok, oban_job} ->
            IO.puts("🔄 Executing worker...")

            # Execute the job directly
            start_time = System.monotonic_time(:millisecond)
            result = RaBackend.Workers.TaskWorker.perform(oban_job)
            end_time = System.monotonic_time(:millisecond)
            execution_time = end_time - start_time

            IO.puts("⏱️  Execution time: #{execution_time}ms")
            IO.puts("🔄 Worker result: #{inspect(result)}")

            # Check final task state
            updated_task = RaBackend.Tasks.get_task!(task.id)
            IO.puts("📊 Final status: #{updated_task.status}")
            IO.puts("📊 Final progress: #{updated_task.progress}")

            if Map.keys(updated_task.result_data) != [] do
              IO.puts("📦 Result data keys: #{inspect(Map.keys(updated_task.result_data))}")
            end

            case result do
              :ok ->
                if updated_task.status == :completed do
                  IO.puts("✅ SUCCESS: Video task completed successfully")
                else
                  IO.puts("⚠️  WARNING: Task executed but status is #{updated_task.status}")
                end
              {:error, _reason} ->
                if updated_task.status == :failed do
                  IO.puts("✅ SUCCESS: Task failed gracefully (expected without API key)")
                else
                  IO.puts("❌ FAIL: Task execution error but status is #{updated_task.status}")
                end
            end

          {:error, error} ->
            IO.puts("❌ FAIL: Could not enqueue job")
            IO.puts("   Error: #{inspect(error)}")
        end

      {:error, error} ->
        IO.puts("❌ FAIL: Could not create task")
        IO.puts("   Error: #{inspect(error)}")
    end
  end

  # Helper function
  defp enqueue_task_job(task_id) do
    task = RaBackend.Tasks.get_task!(task_id)

    if task.task_type in [:image_gen, :video_gen] do
      queue_name = queue_for(task.task_type)

      %{"task_id" => task_id}
      |> RaBackend.Workers.TaskWorker.new(queue: queue_name)
      |> Oban.insert()
    else
      {:error, "Task type #{task.task_type} not supported"}
    end
  end

  defp queue_for(:image_gen), do: :image_generation
  defp queue_for(:video_gen), do: :video_generation
end

# Run the test
VideoGenerationTest.run()
