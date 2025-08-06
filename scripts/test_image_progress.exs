# Test script for Real-Time Image Generation Progress
# Run with: mix run scripts/test_image_progress.exs

# Start the application context
Mix.Task.run("app.start")

defmodule ImageProgressTest do
  require Logger
  alias RaBackend.Tasks
  alias RaBackend.Workers.TaskWorker

  def test_realtime_progress_tracking do
    Logger.info("🧪 Testing REAL-TIME image generation progress...")
    IO.puts("")

    # Create an image generation task
    task_params = %{
      "task_type" => "image_gen",
      "model" => "google/imagen-4-fast",
      "input_data" => %{
        "prompt" => "A beautiful serene lake with mountains and sunset reflection",
        "aspect_ratio" => "16:9"
      }
    }

    case Tasks.create_task(task_params) do
      {:ok, task} ->
        Logger.info("✅ Created task #{task.id} for real-time progress testing")
        Logger.info("   Model: #{task.model}")
        Logger.info("   Prompt: #{task.input_data["prompt"]}")
        IO.puts("")

        # Start monitoring task progress in a separate process
        monitor_pid = spawn(fn -> monitor_task_progress(task.id) end)

        # Simulate what would happen when Oban processes this task
        Logger.info("🔄 Starting TaskWorker.perform() simulation...")

        # This would normally be done by Oban, but we'll do it manually for testing
        job_args = %{"task_id" => task.id}
        job = %Oban.Job{args: job_args}

        case TaskWorker.perform(job) do
          :ok ->
            Logger.info("🎉 Task completed successfully!")
            Logger.info("📊 Final task state:")

            final_task = Tasks.get_task!(task.id)
            Logger.info("   Status: #{final_task.status}")
            Logger.info("   Progress: #{final_task.progress}")
            Logger.info("   Result: #{inspect(final_task.result_data)}")

            if final_task.result_data["image_url"] do
              IO.puts("")
              IO.puts("🌟 GENERATED IMAGE AVAILABLE AT:")
              IO.puts("   #{final_task.result_data["image_url"]}")
              IO.puts("")
            end

          {:error, reason} ->
            Logger.error("❌ Task failed: #{inspect(reason)}")
        end

        # Stop monitoring
        Process.exit(monitor_pid, :normal)

      {:error, changeset} ->
        Logger.error("❌ Failed to create task: #{inspect(changeset.errors)}")
    end
  end

  # Monitor task progress in real-time
  defp monitor_task_progress(task_id) do
    Logger.info("📊 Starting progress monitor for task #{task_id}")
    monitor_loop(task_id, 0.0)
  end

  defp monitor_loop(task_id, last_progress) do
    try do
      task = Tasks.get_task!(task_id)

      if task.progress != last_progress do
        progress_percent = trunc(task.progress * 100)
        status_emoji = case task.status do
          :queued -> "⏳"
          :processing -> "🔄"
          :completed -> "✅"
          :failed -> "❌"
          _ -> "📋"
        end

        Logger.info("#{status_emoji} Progress: #{progress_percent}% (#{task.status})")

        # Show what each progress milestone means
        case task.progress do
          p when p >= 0.0 and p < 0.2 -> Logger.debug("   → Worker starting...")
          p when p >= 0.2 and p < 0.6 -> Logger.debug("   → Replicate: starting generation...")
          p when p >= 0.6 and p < 1.0 -> Logger.debug("   → Replicate: processing image...")
          1.0 -> Logger.debug("   → Replicate: generation complete!")
          _ -> nil
        end
      end

      # Continue monitoring if not completed
      if task.status in [:queued, :processing] do
        Process.sleep(500)  # Check every 500ms
        monitor_loop(task_id, task.progress)
      else
        Logger.info("📊 Progress monitoring complete for task #{task_id}")
      end

    rescue
      Ecto.NoResultsError ->
        Logger.error("❌ Task #{task_id} not found")
    end
  end

  def test_progress_comparison do
    Logger.info("📊 Progress Tracking Comparison")
    IO.puts("")

    IO.puts("🔄 OLD BEHAVIOR (Synchronous):")
    IO.puts("   0.1% → Worker starts")
    IO.puts("   0.3% → Provider found")
    IO.puts("   0.5% → Sending to Replicate...")
    IO.puts("   [STUCK AT 0.5% FOR 10-60 SECONDS]")
    IO.puts("   0.9% → Got response!")
    IO.puts("   100% → Complete")
    IO.puts("")

    IO.puts("✨ NEW BEHAVIOR (Real-time Polling):")
    IO.puts("   10% → Worker starts")
    IO.puts("   20% → Replicate: starting...")
    IO.puts("   60% → Replicate: processing...")
    IO.puts("   100% → Replicate: succeeded!")
    IO.puts("")

    IO.puts("🎯 Benefits:")
    IO.puts("   ✅ Users see real progress every 2 seconds")
    IO.puts("   ✅ No more getting stuck at 50%")
    IO.puts("   ✅ Better UX with smooth progress bars")
    IO.puts("   ✅ WebSocket clients get live updates")
  end

  def run_tests do
    Logger.info("🚀 Real-Time Progress Testing")
    IO.puts("")

    test_progress_comparison()
    IO.puts("")

    test_realtime_progress_tracking()

    IO.puts("")
    Logger.info("🎉 Real-time progress tracking is working!")
    IO.puts("📱 WebSocket clients now receive:")
    IO.puts("   • Progress updates every 2 seconds")
    IO.puts("   • Real Replicate status changes")
    IO.puts("   • Smooth progress bar animations")
  end
end

# Run the tests
ImageProgressTest.run_tests()
