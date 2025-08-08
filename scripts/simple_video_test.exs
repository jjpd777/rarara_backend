# Simple Video Generation Test
# Focus on single video generation with detailed step-by-step logging

defmodule SimpleVideoTest do
  @moduledoc """
  Simple test for video generation with step-by-step logging
  """

  def run do
    IO.puts("🎬 Simple Video Generation Test")
    IO.puts("Prompt: 'The mythical Prometheus stealing the fire from the gods'")
    IO.puts("=" |> String.duplicate(60))

    # Clean up any old tasks first
    cleanup_old_tasks()

    # Run the test
    test_single_video_generation()
  end

    defp cleanup_old_tasks do
    IO.puts("\n🧹 Step 1: Cleaning up old video tasks...")

    import Ecto.Query

    {old_tasks_count, _} = RaBackend.Repo.delete_all(
      from t in RaBackend.Tasks.Task,
      where: t.task_type == :video_gen and t.status in [:queued, :processing]
    )

    {old_jobs_count, _} = RaBackend.Repo.delete_all(
      from j in Oban.Job,
      where: j.queue == "video_generation" and j.state in ["available", "executing"]
    )

    IO.puts("   Deleted #{old_tasks_count} old tasks and #{old_jobs_count} old jobs")
  end

  defp test_single_video_generation do
    IO.puts("\n📋 Step 2: Creating video generation task...")

    task_params = %{
      "task_type" => "video_gen",
      "model" => "bytedance/seedance-1-lite",
      "input_data" => %{
        "prompt" => "The mythical Prometheus stealing the fire from the gods",
        "duration" => 5
      }
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("   ✅ Task created successfully")
        IO.puts("   📊 Task ID: #{task.id}")
        IO.puts("   📊 Status: #{task.status}")
        IO.puts("   📊 Progress: #{task.progress}")
        IO.puts("   📊 Duration: #{task.input_data["duration"]}")

        enqueue_and_execute(task)

      {:error, changeset} ->
        IO.puts("   ❌ Failed to create task: #{inspect(changeset.errors)}")
    end
  end

  defp enqueue_and_execute(task) do
    IO.puts("\n🔄 Step 3: Enqueueing Oban job...")

    case create_oban_job(task.id) do
      {:ok, oban_job} ->
        IO.puts("   ✅ Oban job created")
        IO.puts("   📊 Job ID: #{oban_job.id}")
        IO.puts("   📊 Queue: #{oban_job.queue}")

        execute_worker(task, oban_job)

      {:error, error} ->
        IO.puts("   ❌ Failed to create Oban job: #{inspect(error)}")
    end
  end

  defp execute_worker(task, oban_job) do
    IO.puts("\n⚡ Step 4: Executing worker...")
    IO.puts("   Starting execution at #{DateTime.utc_now()}")

    start_time = System.monotonic_time(:millisecond)

    # Monitor progress in a separate process
    monitor_pid = spawn(fn -> monitor_progress(task.id) end)

    # Execute the worker
    result = RaBackend.Workers.TaskWorker.perform(oban_job)

    # Stop monitoring
    Process.exit(monitor_pid, :normal)

    end_time = System.monotonic_time(:millisecond)
    execution_time = end_time - start_time

    IO.puts("   Execution completed at #{DateTime.utc_now()}")
    IO.puts("   ⏱️  Total execution time: #{execution_time}ms")

    check_final_result(task.id, result)
  end

  defp monitor_progress(task_id) do
    IO.puts("\n📈 Step 5: Monitoring progress...")
    monitor_loop(task_id, 0.0, 0)
  end

  defp monitor_loop(task_id, last_progress, count) do
    if count < 30 do  # Monitor for max 30 iterations
      try do
        task = RaBackend.Tasks.get_task!(task_id)

        if task.progress != last_progress do
          IO.puts("   📊 Progress update: #{task.progress} (status: #{task.status})")
        end

        if task.status in [:completed, :failed] do
          IO.puts("   🏁 Task finished with status: #{task.status}")
        else
          Process.sleep(1000)  # Check every second
          monitor_loop(task_id, task.progress, count + 1)
        end
      rescue
        _ ->
          Process.sleep(1000)
          monitor_loop(task_id, last_progress, count + 1)
      end
    else
      IO.puts("   ⏰ Monitoring timeout after 30 seconds")
    end
  end

  defp check_final_result(task_id, worker_result) do
    IO.puts("\n🎯 Step 6: Final results...")

    final_task = RaBackend.Tasks.get_task!(task_id)

    IO.puts("   📊 Worker result: #{inspect(worker_result)}")
    IO.puts("   📊 Final task status: #{final_task.status}")
    IO.puts("   📊 Final progress: #{final_task.progress}")

    case final_task.status do
      :completed ->
        IO.puts("   ✅ SUCCESS: Video generation completed!")
        if final_task.result_data["video_url"] do
          IO.puts("   🎬 Video URL: #{final_task.result_data["video_url"]}")
        end

      :failed ->
        IO.puts("   ❌ Video generation failed")
        if final_task.result_data["error"] do
          IO.puts("   🚨 Error: #{final_task.result_data["error"]}")
        end

      other ->
        IO.puts("   ⚠️  Unexpected status: #{other}")
    end
  end

  # Helper function to create Oban job
  defp create_oban_job(task_id) do
    %{"task_id" => task_id}
    |> RaBackend.Workers.TaskWorker.new(queue: :video_generation)
    |> Oban.insert()
  end
end

# Run the test
SimpleVideoTest.run()
