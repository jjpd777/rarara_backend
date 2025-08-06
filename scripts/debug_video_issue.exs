# Debug script to investigate video generation issue

defmodule VideoDebug do
  def run do
    IO.puts("🔍 Debug Video Generation Issue")
    IO.puts("================================")

    check_old_tasks()
    check_oban_jobs()
    test_simple_creation()
  end

  defp check_old_tasks do
    IO.puts("\n📋 Checking for old video tasks...")

    import Ecto.Query
    tasks = RaBackend.Repo.all(
      from t in RaBackend.Tasks.Task,
      where: t.task_type == :video_gen,
      order_by: [desc: t.inserted_at],
      limit: 5
    )

    IO.puts("Found #{length(tasks)} recent video tasks:")
    Enum.each(tasks, fn task ->
      IO.puts("  Task #{task.id}: status=#{task.status}, duration=#{task.input_data["duration"]}")
    end)
  end

  defp check_oban_jobs do
    IO.puts("\n📋 Checking Oban video jobs...")

    import Ecto.Query
    jobs = RaBackend.Repo.all(
      from j in Oban.Job,
      where: j.queue == "video_generation",
      order_by: [desc: j.inserted_at],
      limit: 5
    )

    IO.puts("Found #{length(jobs)} video generation jobs:")
    Enum.each(jobs, fn job ->
      IO.puts("  Job #{job.id}: state=#{job.state}, task_id=#{job.args["task_id"]}")
    end)
  end

  defp test_simple_creation do
    IO.puts("\n📋 Testing simple task creation with duration 5...")

    task_params = %{
      "task_type" => "video_gen",
      "model" => "bytedance/seedance-1-pro",
      "input_data" => %{
        "prompt" => "Simple test prompt",
        "duration" => 5
      }
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ Task created successfully:")
        IO.puts("   ID: #{task.id}")
        IO.puts("   Duration: #{task.input_data["duration"]} (type: #{task.input_data["duration"] |> :erlang.term_to_binary() |> :erlang.binary_to_term() |> :erlang.element(1)})")
        IO.puts("   Full input: #{inspect(task.input_data)}")

        # Test worker execution on this specific task
        test_worker_with_task(task)

      {:error, changeset} ->
        IO.puts("❌ Failed to create task: #{inspect(changeset.errors)}")
    end
  end

  defp test_worker_with_task(task) do
    IO.puts("\n📋 Testing worker execution on new task...")

    # Create Oban job
    {:ok, oban_job} = %{"task_id" => task.id}
    |> RaBackend.Workers.TaskWorker.new(queue: :video_generation)
    |> Oban.insert()

    IO.puts("Created Oban job: #{oban_job.id}")

    # Execute directly
    result = RaBackend.Workers.TaskWorker.perform(oban_job)

    # Check result
    updated_task = RaBackend.Tasks.get_task!(task.id)
    IO.puts("Worker result: #{inspect(result)}")
    IO.puts("Final task status: #{updated_task.status}")

    if updated_task.result_data["error"] do
      IO.puts("Error details: #{updated_task.result_data["error"]}")
    end
  end
end

VideoDebug.run()
