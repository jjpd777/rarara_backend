# scripts/task_system_test.exs
defmodule Scripts.TaskSystemTest do
  @moduledoc """
  Comprehensive test suite for the Task system.
  Call Scripts.TaskSystemTest.run/0 from IEx.

  Usage:
    iex -S mix
    Scripts.TaskSystemTest.run()
  """

  alias RaBackend.{Tasks, Repo}
  alias RaBackend.Tasks.Task
  alias RaBackend.Workers.TaskWorker
  alias RaBackendWeb.TaskController

  def run do
    IO.puts("\n🚀 Starting Task System Comprehensive Test\n")

    results = %{
      database: test_database_connectivity(),
      task_creation: test_task_creation(),
      oban_system: test_oban_system(),
      controller: test_controller_flow(),
      pubsub: test_pubsub_system(),
      processes: test_process_inspection()
    }

    print_summary(results)
    results
  end

  # ================================
  # LAYER 1: Database Connectivity
  # ================================
  defp test_database_connectivity do
    IO.puts("=== LAYER 1: Database Connectivity ===")

    tests = [
      {"Basic connection", fn ->
        case Repo.query("SELECT 1") do
          {:ok, %Postgrex.Result{}} -> {:ok, "Connection successful"}
          error -> error
        end
      end},
      {"Tables exist", fn ->
        case Repo.query("SELECT tablename FROM pg_tables WHERE schemaname = 'public'") do
          {:ok, %Postgrex.Result{rows: rows}} -> {:ok, "Found #{length(rows)} tables"}
          error -> error
        end
      end},
      {"Task table accessible", fn ->
        case Repo.query("SELECT COUNT(*) FROM tasks") do
          {:ok, %Postgrex.Result{rows: [[count]]}} -> {:ok, "#{count} tasks in database"}
          error -> error
        end
      end}
    ]

    run_test_group(tests)
  end

  # ================================
  # LAYER 2: Task Creation
  # ================================
  defp test_task_creation do
    IO.puts("\n=== LAYER 2: Task Creation (Without Oban) ===")

    tests = [
      {"Create simple task", fn ->
        case Tasks.create_task(%{
          "prompt" => "test prompt",
          "input_data" => %{"message" => "hello world"}
        }) do
          {:ok, task} -> {:ok, "Task created with ID: #{task.id}"}
          error -> error
        end
      end},
      {"Create task with complex data", fn ->
        case Tasks.create_task(%{
          "prompt" => "complex test",
          "input_data" => %{
            "nested" => %{"data" => "structure"},
            "array" => [1, 2, 3],
            "boolean" => true
          }
        }) do
          {:ok, task} -> {:ok, "Complex task created with ID: #{task.id}"}
          error -> error
        end
      end},
      {"Validate task retrieval", fn ->
        {:ok, task} = Tasks.create_task(%{"prompt" => "retrieval test"})
        retrieved = Tasks.get_task!(task.id)
        if retrieved.id == task.id do
          {:ok, "Retrieved task matches: #{task.id}"}
        else
          {:error, "ID mismatch"}
        end
      end}
    ]

    run_test_group(tests)
  end

  # ================================
  # LAYER 3: Oban Job System
  # ================================
  defp test_oban_system do
    IO.puts("\n=== LAYER 3: Oban Job System ===")

    tests = [
      {"Oban configuration", fn ->
        config = Oban.config()
        {:ok, "Queues: #{inspect(config.queues)}"}
      end},
      {"Create job changeset", fn ->
        job = TaskWorker.new(%{task_id: "test-id"})
        # The worker is in the 'changes' map, not a direct field
        worker_module = job.changes.worker
        {:ok, "Job worker: #{worker_module}"}
      end},
      {"Insert Oban job", fn ->
        {:ok, task} = Tasks.create_task(%{"prompt" => "oban test"})
        job = TaskWorker.new(%{task_id: task.id})
        case Oban.insert(job) do
          {:ok, %Oban.Job{id: job_id}} -> {:ok, "Job inserted with ID: #{job_id}"}
          error -> error
        end
      end}
    ]

    run_test_group(tests)
  end

  # ================================
  # LAYER 4: Controller Flow
  # ================================
  defp test_controller_flow do
    IO.puts("\n=== LAYER 4: Full Controller Flow ===")

    tests = [
      {"Controller create action", fn ->
        params = %{
          "prompt" => "controller test",
          "input_data" => %{"source" => "script_test"}
        }

        # Create mock connection
        conn = %Plug.Conn{
          method: "POST",
          request_path: "/api/tasks",
          resp_body: nil,
          status: nil
        }

        result = TaskController.create(conn, params)
        {:ok, "Status: #{result.status}"}
      end}
    ]

    run_test_group(tests)
  end

  # ================================
  # LAYER 5: PubSub System
  # ================================
  defp test_pubsub_system do
    IO.puts("\n=== LAYER 5: WebSocket/PubSub Testing ===")

    tests = [
      {"PubSub subscription and progress update", fn ->
        {:ok, task} = Tasks.create_task(%{"prompt" => "pubsub test"})

        # Subscribe to updates
        Phoenix.PubSub.subscribe(RaBackend.PubSub, "task:#{task.id}")

        # Update progress
        Tasks.update_task_progress(task.id, 0.5)

        # Check for message
        receive do
          {:progress_update, update} ->
            {:ok, "Received: #{update.progress * 100}% progress"}
        after 1000 ->
          {:error, "No progress update received"}
        end
      end}
    ]

    run_test_group(tests)
  end

  # ================================
  # LAYER 6: Process Inspection
  # ================================
  defp test_process_inspection do
    IO.puts("\n=== LAYER 6: Process Inspection ===")

    tests = [
      {"Count running processes", fn ->
        count = Process.list() |> length()
        {:ok, "#{count} processes running"}
      end},
      {"Find Oban processes", fn ->
        oban_procs = Process.registered()
        |> Enum.filter(&String.contains?(to_string(&1), "Oban"))
        |> length()
        {:ok, "#{oban_procs} Oban processes found"}
      end},
      {"Check supervision tree", fn ->
        children = Supervisor.which_children(RaBackend.Supervisor)
        {:ok, "#{length(children)} supervised children"}
      end}
    ]

    run_test_group(tests)
  end

  # ================================
  # Helper Functions
  # ================================
  defp run_test_group(tests) do
    results = Enum.map(tests, fn {name, test_fn} ->
      IO.write("  #{name}... ")

      result = try do
        case test_fn.() do
          {:ok, _} = success -> success
          {:ok, _, _} = success -> success
          {:error, _} = error -> error
          other -> {:ok, inspect(other)}
        end
      rescue
        error -> {:error, Exception.message(error)}
      catch
        :exit, reason -> {:error, "Exit: #{inspect(reason)}"}
      end

      case result do
        {:ok, details} ->
          IO.puts("✓ PASS #{if details, do: "- #{details}", else: ""}")
          {name, :pass, details}
        {:error, reason} ->
          IO.puts("❌ FAIL - #{reason}")
          {name, :fail, reason}
      end
    end)

    results
  end

  defp print_summary(results) do
    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("📊 TEST SUMMARY")
    IO.puts(String.duplicate("=", 50))

    Enum.each(results, fn {layer, tests} ->
      passed = Enum.count(tests, fn {_, status, _} -> status == :pass end)
      total = length(tests)

      status_icon = if passed == total, do: "✅", else: "⚠️"
      IO.puts("#{status_icon} #{String.upcase(to_string(layer))}: #{passed}/#{total} passed")

      # Show failures
      tests
      |> Enum.filter(fn {_, status, _} -> status == :fail end)
      |> Enum.each(fn {name, _, reason} ->
        IO.puts("    ❌ #{name}: #{reason}")
      end)
    end)

    total_tests = results |> Enum.flat_map(fn {_, tests} -> tests end) |> length()
    total_passed = results
    |> Enum.flat_map(fn {_, tests} -> tests end)
    |> Enum.count(fn {_, status, _} -> status == :pass end)

    IO.puts("\n🎯 OVERALL: #{total_passed}/#{total_tests} tests passed")

    if total_passed == total_tests do
      IO.puts("🎉 All systems operational!")
    else
      IO.puts("🔧 Some issues need attention.")
    end
  end

  # ================================
  # Stress Testing (Optional)
  # ================================
  def stress_test(num_tasks \\ 10) do
    IO.puts("\n🏋️ Running stress test with #{num_tasks} concurrent tasks...")

    start_time = System.monotonic_time(:millisecond)

    tasks = 1..num_tasks
    |> Enum.map(fn i ->
      Task.async(fn ->
        Tasks.create_task(%{
          "prompt" => "stress test #{i}",
          "input_data" => %{"batch" => i, "timestamp" => DateTime.utc_now()}
        })
      end)
    end)
    |> Enum.map(&Task.await(&1, 10_000))

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    successes = Enum.count(tasks, fn
      {:ok, _} -> true
      _ -> false
    end)

    IO.puts("⏱️  Duration: #{duration}ms")
    IO.puts("✅ Success rate: #{successes}/#{num_tasks}")
    IO.puts("📈 Avg time per task: #{duration / num_tasks}ms")

    tasks
  end
end
