# Test script to verify Oban integration for image generation
# This script tests that:
# 1. Image tasks get queued to Oban
# 2. Text tasks do NOT get queued to Oban
# 3. Worker processes only image/video tasks

defmodule ObanIntegrationTest do
  @moduledoc """
  Test Oban integration for image generation tasks
  """

    def run do
    IO.puts("🧪 Testing Oban Integration for Image Generation")
    IO.puts("=" |> String.duplicate(50))

    test_image_task_queued()
    test_text_task_not_queued()
    test_worker_safety_check()

    IO.puts("\n✅ All Oban integration tests completed!")
  end

  defp test_image_task_queued do
    IO.puts("\n📋 Test 1: Image task should be queued to Oban")

    # Create an image generation task
    task_params = %{
      "task_type" => "image_gen",
      "model" => "google/imagen-4-fast",
      "input_data" => %{"prompt" => "A test image"}
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ Task created: #{task.id}")

        # Count Oban jobs before
        jobs_before = count_oban_jobs()
        IO.puts("📊 Oban jobs before: #{jobs_before}")

                # Test the enqueue logic directly
        try do
          result = simulate_enqueue_task_job(task.id)
          IO.puts("🔄 Enqueue result: #{inspect(result)}")

          # Count Oban jobs after
          jobs_after = count_oban_jobs()
          IO.puts("📊 Oban jobs after: #{jobs_after}")

          if jobs_after > jobs_before do
            IO.puts("✅ SUCCESS: Image task was queued to Oban")
          else
            IO.puts("❌ FAIL: Image task was NOT queued to Oban")
          end
        rescue
          error ->
            IO.puts("❌ Error during enqueue: #{inspect(error)}")
        end

      {:error, reason} ->
        IO.puts("❌ Failed to create task: #{inspect(reason)}")
    end
  end

  defp test_text_task_not_queued do
    IO.puts("\n📋 Test 2: Text task should NOT be queued to Oban")

    # Create a text generation task
    task_params = %{
      "task_type" => "text_gen",
      "model" => "gpt-4.1",
      "input_data" => %{"prompt" => "A test text"}
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ Task created: #{task.id}")

        # Count Oban jobs before
        jobs_before = count_oban_jobs()
        IO.puts("📊 Oban jobs before: #{jobs_before}")

        # Simulate the channel enqueue (this should NOT queue the job)
        try do
          result = simulate_enqueue_task_job(task.id)
          IO.puts("🔄 Enqueue result: #{inspect(result)}")

          # Count Oban jobs after
          jobs_after = count_oban_jobs()
          IO.puts("📊 Oban jobs after: #{jobs_after}")

          if jobs_after == jobs_before do
            IO.puts("✅ SUCCESS: Text task was NOT queued to Oban (as expected)")
          else
            IO.puts("❌ FAIL: Text task was incorrectly queued to Oban")
          end
        rescue
          error ->
            IO.puts("❌ Error during enqueue test: #{inspect(error)}")
        end

      {:error, reason} ->
        IO.puts("❌ Failed to create task: #{inspect(reason)}")
    end
  end

  defp test_worker_safety_check do
    IO.puts("\n📋 Test 3: Worker should reject text generation tasks")

    # Create a text task (normally this wouldn't be queued, but let's test worker safety)
    task_params = %{
      "task_type" => "text_gen",
      "model" => "gpt-4.1",
      "input_data" => %{"prompt" => "Test prompt"}
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ Task created: #{task.id}")

        # Simulate direct worker call (bypassing channel filter)
        job_args = %{"task_id" => task.id}
        oban_job = %Oban.Job{args: job_args}

        try do
          result = RaBackend.Workers.TaskWorker.perform(oban_job)
          IO.puts("🔄 Worker result: #{inspect(result)}")

          case result do
            {:error, msg} when is_binary(msg) ->
              if String.contains?(msg, "disallowed") do
                IO.puts("✅ SUCCESS: Worker correctly rejected text_gen task")
              else
                IO.puts("❌ FAIL: Worker should have rejected text_gen task with 'disallowed' message")
              end
            _ ->
              IO.puts("❌ FAIL: Worker should have rejected text_gen task")
          end
        rescue
          error ->
            IO.puts("❌ Error in worker test: #{inspect(error)}")
        end

      {:error, reason} ->
        IO.puts("❌ Failed to create task: #{inspect(reason)}")
    end
  end

  # Helper function to simulate the enqueue logic
  defp simulate_enqueue_task_job(task_id) do
    task = RaBackend.Tasks.get_task!(task_id)

    # This replicates the logic in TaskChannel.enqueue_task_job/1
    if task.task_type in [:image_gen, :video_gen] do
      queue_name = queue_for(task.task_type)

      %{task_id: task_id}
      |> RaBackend.Workers.TaskWorker.new(queue: queue_name)
      |> Oban.insert()
    else
      {:error, "Task type #{task.task_type} not enqueued - only image_gen and video_gen use Oban"}
    end
  end

  defp queue_for(:image_gen), do: :image_generation
  defp queue_for(:video_gen), do: :video_generation

  defp count_oban_jobs do
    import Ecto.Query
    RaBackend.Repo.aggregate(Oban.Job, :count, :id)
  end
end

# Run the test
ObanIntegrationTest.run()
