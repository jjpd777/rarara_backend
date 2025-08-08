# Simple Video Generation Test
# Focus on single video generation with detailed step-by-step logging

defmodule SimpleVideoTest do
  @moduledoc """
  Simple test for video generation with step-by-step logging.
  This version only enqueues the job and waits for the background worker to process it.
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

        enqueue_and_monitor(task)

      {:error, changeset} ->
        IO.puts("   ❌ Failed to create task: #{inspect(changeset.errors)}")
    end
  end

  defp enqueue_and_monitor(task) do
    IO.puts("\n🔄 Step 3: Enqueueing Oban job...")

    case create_oban_job(task.id) do
      {:ok, oban_job} ->
        IO.puts("   ✅ Oban job enqueued successfully")
        IO.puts("   📊 Job ID: #{oban_job.id}")
        IO.puts("   📊 Queue: #{oban_job.queue}")

        wait_for_completion(task.id)

      {:error, error} ->
        IO.puts("   ❌ Failed to create Oban job: #{inspect(error)}")
    end
  end

  defp wait_for_completion(task_id) do
    IO.puts("\n⏳ Step 4: Waiting for background worker to complete the task...")
    start_time = System.monotonic_time(:millisecond)

    # Blocking loop to monitor task progress
    monitor_loop(task_id, 0.0, 0)

    end_time = System.monotonic_time(:millisecond)
    execution_time = end_time - start_time
    IO.puts("   ⏱️  Total wait time: #{execution_time}ms")

    check_final_result(task_id)
  end

  defp monitor_loop(task_id, last_progress, count) do
    # Wait for a maximum of 60 seconds (60 iterations * 1s sleep)
    if count >= 60 do
      IO.puts("   ⏰ Monitoring timeout after 60 seconds. Task may not have completed.")
      :timeout
    else
      task = RaBackend.Tasks.get_task!(task_id)

      if task.progress != last_progress do
        IO.puts("   📈 Progress update: #{Float.round(task.progress * 100, 2)}% (Status: #{task.status})")
      end

      case task.status do
        :completed ->
          IO.puts("   🏁 Task finished with status: :completed")
          :ok
        :failed ->
          IO.puts("   🏁 Task finished with status: :failed")
          :ok
        _ ->
          Process.sleep(1000) # Check every second
          monitor_loop(task_id, task.progress, count + 1)
      end
    end
  end

  defp check_final_result(task_id) do
    IO.puts("\n🎯 Step 5: Final results...")

    final_task = RaBackend.Tasks.get_task!(task_id)

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
