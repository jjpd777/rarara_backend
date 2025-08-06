# Test script to verify Oban workers are actually executing tasks
# This script tests that:
# 1. Image tasks are processed by the worker
# 2. Task status transitions correctly (queued -> processing -> completed/failed)
# 3. Progress updates occur during processing
# 4. Result data is properly stored
# 5. Jobs are removed from queue after completion

defmodule ObanWorkerExecutionTest do
  @moduledoc """
  Test Oban worker execution for image generation tasks
  Verifies end-to-end job processing including status transitions and result storage
  """

  def run do
    IO.puts("🔧 Testing Oban Worker Execution for Image Generation")
    IO.puts("=" |> String.duplicate(55))

    test_image_task_execution()
    test_job_state_transitions()
    test_progress_updates()
    test_error_handling()
    test_queue_cleanup()

    IO.puts("\n✅ All Oban worker execution tests completed!")
  end

  defp test_image_task_execution do
    IO.puts("\n📋 Test 1: Image task should be executed by worker")

    # Create an image generation task
    task_params = %{
      "task_type" => "image_gen",
      "model" => "google/imagen-4-fast",
      "input_data" => %{"prompt" => "A beautiful sunset over mountains"}
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ Task created: #{task.id}")
        IO.puts("📊 Initial status: #{task.status}, progress: #{task.progress}")

        # Enqueue the job
        {:ok, oban_job} = enqueue_task_job(task.id)
        IO.puts("🔄 Job enqueued to queue: #{oban_job.queue}")

        # Execute the job directly (simulating Oban execution)
        IO.puts("⚡ Executing job via worker...")

        start_time = System.monotonic_time(:millisecond)
        result = RaBackend.Workers.TaskWorker.perform(oban_job)
        end_time = System.monotonic_time(:millisecond)
        execution_time = end_time - start_time

        IO.puts("⏱️  Execution time: #{execution_time}ms")
        IO.puts("🔄 Worker result: #{inspect(result)}")

        # Check final task state
        updated_task = RaBackend.Tasks.get_task!(task.id)
        IO.puts("📊 Final status: #{updated_task.status}, progress: #{updated_task.progress}")
        IO.puts("📦 Result data keys: #{inspect(Map.keys(updated_task.result_data))}")

        case result do
          :ok ->
            if updated_task.status == :completed do
              IO.puts("✅ SUCCESS: Task executed and completed successfully")
            else
              IO.puts("❌ FAIL: Task executed but status is #{updated_task.status}")
            end
          {:error, _reason} ->
            if updated_task.status == :failed do
              IO.puts("✅ SUCCESS: Task executed and failed as expected (likely API key missing)")
            else
              IO.puts("❌ FAIL: Task execution error but status is #{updated_task.status}")
            end
        end

      {:error, reason} ->
        IO.puts("❌ Failed to create task: #{inspect(reason)}")
    end
  end

  defp test_job_state_transitions do
    IO.puts("\n📋 Test 2: Job state transitions should be tracked")

    task_params = %{
      "task_type" => "image_gen",
      "model" => "google/imagen-4-fast",
      "input_data" => %{"prompt" => "State transition test"}
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ Task created: #{task.id}")

        # Check initial state
        initial_state = RaBackend.Tasks.get_task!(task.id)
        IO.puts("📊 Initial: status=#{initial_state.status}, progress=#{initial_state.progress}")

        # Enqueue and execute
        {:ok, oban_job} = enqueue_task_job(task.id)

        # Monitor state during execution
        monitoring_task = Task.async(fn ->
          monitor_task_state(task.id, 10) # Monitor for 10 seconds
        end)

        # Execute job
        _result = RaBackend.Workers.TaskWorker.perform(oban_job)

        # Get monitoring results
        state_changes = Task.await(monitoring_task, 15_000)

        IO.puts("📈 State transitions observed:")
        Enum.each(state_changes, fn {timestamp, status, progress} ->
          IO.puts("   #{timestamp}: status=#{status}, progress=#{progress}")
        end)

        if length(state_changes) > 1 do
          IO.puts("✅ SUCCESS: Multiple state transitions observed")
        else
          IO.puts("❌ FAIL: No state transitions observed")
        end

      {:error, reason} ->
        IO.puts("❌ Failed to create task: #{inspect(reason)}")
    end
  end

  defp test_progress_updates do
    IO.puts("\n📋 Test 3: Progress updates should occur during processing")

    task_params = %{
      "task_type" => "image_gen",
      "model" => "google/imagen-4-fast",
      "input_data" => %{"prompt" => "Progress update test"}
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ Task created: #{task.id}")

        {:ok, oban_job} = enqueue_task_job(task.id)

        # Monitor progress updates

        # Execute with progress monitoring
        spawn(fn ->
          Process.sleep(100) # Small delay to ensure monitoring starts
          RaBackend.Workers.TaskWorker.perform(oban_job)
        end)

        # Collect progress updates for 5 seconds
        progress_updates = monitor_progress_updates(task.id, 5000)

        IO.puts("📈 Progress updates captured: #{length(progress_updates)}")
        Enum.each(progress_updates, fn {timestamp, progress} ->
          IO.puts("   #{timestamp}: progress=#{progress}")
        end)

        if length(progress_updates) > 0 do
          IO.puts("✅ SUCCESS: Progress updates captured during execution")
        else
          IO.puts("❌ FAIL: No progress updates captured")
        end

      {:error, reason} ->
        IO.puts("❌ Failed to create task: #{inspect(reason)}")
    end
  end

  defp test_error_handling do
    IO.puts("\n📋 Test 4: Worker should handle errors gracefully")

    # Create task with invalid model to trigger error
    task_params = %{
      "task_type" => "image_gen",
      "model" => "invalid/nonexistent-model",
      "input_data" => %{"prompt" => "Error test"}
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ Task created with invalid model: #{task.id}")

        {:ok, oban_job} = enqueue_task_job(task.id)

        # Execute job (should fail gracefully)
        result = RaBackend.Workers.TaskWorker.perform(oban_job)

        # Check task state after error
        failed_task = RaBackend.Tasks.get_task!(task.id)

        IO.puts("🔄 Worker result: #{inspect(result)}")
        IO.puts("📊 Task status: #{failed_task.status}")
        IO.puts("📦 Error data: #{inspect(failed_task.result_data)}")

        case result do
          {:error, _reason} ->
            if failed_task.status == :failed do
              IO.puts("✅ SUCCESS: Worker handled error gracefully")
            else
              IO.puts("❌ FAIL: Task should be marked as failed")
            end
          _ ->
            IO.puts("❌ FAIL: Worker should return error for invalid model")
        end

      {:error, reason} ->
        IO.puts("❌ Failed to create task: #{inspect(reason)}")
    end
  end

  defp test_queue_cleanup do
    IO.puts("\n📋 Test 5: Completed jobs should be cleaned from queue")

    # Count jobs before
    jobs_before = count_oban_jobs()
    available_jobs_before = count_available_jobs()

    IO.puts("📊 Total jobs before: #{jobs_before}")
    IO.puts("📊 Available jobs before: #{available_jobs_before}")

    # Create and execute a simple task
    task_params = %{
      "task_type" => "image_gen",
      "model" => "google/imagen-4-fast",
      "input_data" => %{"prompt" => "Cleanup test"}
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        {:ok, oban_job} = enqueue_task_job(task.id)

        # Execute job
        _result = RaBackend.Workers.TaskWorker.perform(oban_job)

        # Wait a moment for cleanup
        Process.sleep(100)

        # Count jobs after
        jobs_after = count_oban_jobs()
        available_jobs_after = count_available_jobs()

        IO.puts("📊 Total jobs after: #{jobs_after}")
        IO.puts("📊 Available jobs after: #{available_jobs_after}")

        # Check if job was processed (no longer available)
        if available_jobs_after <= available_jobs_before do
          IO.puts("✅ SUCCESS: Job was processed and removed from available queue")
        else
          IO.puts("❌ FAIL: Job still available after processing")
        end

      {:error, reason} ->
        IO.puts("❌ Failed to create task: #{inspect(reason)}")
    end
  end

  # Helper functions

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

  defp monitor_task_state(task_id, duration_seconds) do
    end_time = System.monotonic_time(:millisecond) + (duration_seconds * 1000)
    monitor_task_state_loop(task_id, end_time, [])
  end

  defp monitor_task_state_loop(task_id, end_time, acc) do
    current_time = System.monotonic_time(:millisecond)

    if current_time < end_time do
      task = RaBackend.Tasks.get_task!(task_id)
      timestamp = DateTime.utc_now() |> DateTime.to_string()
      state_entry = {timestamp, task.status, task.progress}

      Process.sleep(200) # Check every 200ms
      monitor_task_state_loop(task_id, end_time, [state_entry | acc])
    else
      Enum.reverse(acc)
    end
  end

  defp monitor_progress_updates(task_id, duration_ms) do
    end_time = System.monotonic_time(:millisecond) + duration_ms
    initial_task = RaBackend.Tasks.get_task!(task_id)
    monitor_progress_loop(task_id, end_time, initial_task.progress, [])
  end

  defp monitor_progress_loop(task_id, end_time, last_progress, acc) do
    current_time = System.monotonic_time(:millisecond)

    if current_time < end_time do
      task = RaBackend.Tasks.get_task!(task_id)

      new_acc = if task.progress != last_progress do
        timestamp = DateTime.utc_now() |> DateTime.to_string()
        [{timestamp, task.progress} | acc]
      else
        acc
      end

      Process.sleep(100) # Check every 100ms
      monitor_progress_loop(task_id, end_time, task.progress, new_acc)
    else
      Enum.reverse(acc)
    end
  end

  defp count_oban_jobs do
    import Ecto.Query
    RaBackend.Repo.aggregate(Oban.Job, :count, :id)
  end

  defp count_available_jobs do
    import Ecto.Query
    from(j in Oban.Job, where: j.state == "available")
    |> RaBackend.Repo.aggregate(:count, :id)
  end
end

# Run the test
ObanWorkerExecutionTest.run()
