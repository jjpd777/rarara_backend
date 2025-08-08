# Test script to verify idempotency implementation for video generation
# This script tests:
# 1. Video tasks with idempotency keys work correctly
# 2. Duplicate requests return the same task
# 3. Race conditions are handled properly
# 4. Image tasks are not affected by idempotency
# 5. Cleanup functionality works

defmodule IdempotencyTest do
  @moduledoc """
  Comprehensive test for video generation idempotency implementation
  """

  def run do
    IO.puts("🔧 Testing Idempotency Implementation for Video Generation")
    IO.puts("=" |> String.duplicate(55))

    test_video_idempotency_basic()
    test_video_idempotency_duplicate()
    test_video_without_idempotency_key()
    test_image_generation_unaffected()
    test_race_condition_simulation()
    test_cleanup_functionality()

    IO.puts("\n✅ All idempotency tests completed!")
  end

  defp test_video_idempotency_basic do
    IO.puts("\n📋 Test 1: Basic video generation with idempotency key")

    user_id = "11111111-1111-1111-1111-111111111111"
    idempotency_key = "test-video-#{System.unique_integer([:positive])}"

    # Store idempotency key
    case RaBackend.Idempotency.store_key(user_id, idempotency_key) do
      {:ok, _record} ->
        IO.puts("✅ SUCCESS: Idempotency key stored successfully")

      {:error, reason} ->
        IO.puts("❌ FAIL: Could not store idempotency key: #{inspect(reason)}")
        :error
    end

    # Create a video task
    task_params = %{
      "task_type" => "video_gen",
      "model" => "bytedance/seedance-1-lite",
      "user_id" => user_id,
      "input_data" => %{
        "prompt" => "A majestic eagle soaring through clouds",
        "duration" => 5
      }
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ SUCCESS: Video task created with ID: #{task.id}")

        # Link the task to idempotency key
        case RaBackend.Idempotency.link_task_to_key(user_id, idempotency_key, task.id) do
          :ok ->
            IO.puts("✅ SUCCESS: Task linked to idempotency key")

          {:error, reason} ->
            IO.puts("❌ FAIL: Could not link task to key: #{inspect(reason)}")
        end

      {:error, changeset} ->
        IO.puts("❌ FAIL: Could not create video task")
        IO.puts("   Errors: #{inspect(changeset.errors)}")
    end
  end

  defp test_video_idempotency_duplicate do
    IO.puts("\n📋 Test 2: Duplicate video request returns same task")

    user_id = "11111111-1111-1111-1111-111111111111"
    idempotency_key = "test-duplicate-#{System.unique_integer([:positive])}"

    # First request
    task_params = %{
      "task_type" => "video_gen",
      "model" => "bytedance/seedance-1-lite",
      "user_id" => user_id,
      "input_data" => %{
        "prompt" => "A peaceful meadow with butterflies",
        "duration" => 5
      }
    }

    {:ok, _} = RaBackend.Idempotency.store_key(user_id, idempotency_key)
    {:ok, first_task} = RaBackend.Tasks.create_task(task_params)
    :ok = RaBackend.Idempotency.link_task_to_key(user_id, idempotency_key, first_task.id)

    IO.puts("✅ First task created: #{first_task.id}")

    # Simulate duplicate request
    case RaBackend.Idempotency.find_task_by_key(user_id, idempotency_key) do
      {:ok, found_task} ->
        if found_task.id == first_task.id do
          IO.puts("✅ SUCCESS: Duplicate request returned same task ID")
        else
          IO.puts("❌ FAIL: Different task returned for duplicate request")
        end

      {:error, reason} ->
        IO.puts("❌ FAIL: Could not find task for duplicate request: #{inspect(reason)}")
    end
  end

  defp test_video_without_idempotency_key do
    IO.puts("\n📋 Test 3: Video generation without idempotency key still works")

    user_id = "11111111-1111-1111-1111-111111111111"

    task_params = %{
      "task_type" => "video_gen",
      "model" => "bytedance/seedance-1-lite",
      "user_id" => user_id,
      "input_data" => %{
        "prompt" => "A robot dancing in the rain",
        "duration" => 5
      }
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ SUCCESS: Video task created without idempotency key: #{task.id}")

      {:error, changeset} ->
        IO.puts("❌ FAIL: Could not create video task without idempotency key")
        IO.puts("   Errors: #{inspect(changeset.errors)}")
    end
  end

  defp test_image_generation_unaffected do
    IO.puts("\n📋 Test 4: Image generation unaffected by idempotency changes")

    user_id = "11111111-1111-1111-1111-111111111111"

    task_params = %{
      "task_type" => "image_gen",
      "model" => "google/imagen-4-fast",
      "user_id" => user_id,
      "input_data" => %{
        "prompt" => "A beautiful sunset over mountains",
        "aspect_ratio" => "16:9"
      }
    }

    case RaBackend.Tasks.create_task(task_params) do
      {:ok, task} ->
        IO.puts("✅ SUCCESS: Image task created normally: #{task.id}")

      {:error, changeset} ->
        IO.puts("❌ FAIL: Could not create image task")
        IO.puts("   Errors: #{inspect(changeset.errors)}")
    end
  end

  defp test_race_condition_simulation do
    IO.puts("\n📋 Test 5: Race condition handling")

    user_id = "11111111-1111-1111-1111-111111111111"
    idempotency_key = "test-race-#{System.unique_integer([:positive])}"

    # Store key once
    {:ok, _} = RaBackend.Idempotency.store_key(user_id, idempotency_key)

    # Try to store the same key again (simulating race condition)
    case RaBackend.Idempotency.store_key(user_id, idempotency_key) do
      {:error, :already_exists} ->
        IO.puts("✅ SUCCESS: Race condition properly detected and handled")

      {:ok, _} ->
        IO.puts("❌ FAIL: Duplicate key storage allowed (should be prevented)")

      {:error, reason} ->
        IO.puts("⚠️  WARNING: Unexpected error in race condition test: #{inspect(reason)}")
    end
  end

  defp test_cleanup_functionality do
    IO.puts("\n📋 Test 6: Cleanup functionality")

    user_id = "11111111-1111-1111-1111-111111111111"
    idempotency_key = "test-cleanup-#{System.unique_integer([:positive])}"

    # Create an idempotency key
    {:ok, _} = RaBackend.Idempotency.store_key(user_id, idempotency_key)

    # Test manual cleanup (this won't delete recent keys, but tests the function)
    case RaBackend.Idempotency.cleanup_expired_keys() do
      {:ok, count} ->
        IO.puts("✅ SUCCESS: Cleanup completed, removed #{count} expired keys")

      {:error, reason} ->
        IO.puts("❌ FAIL: Cleanup failed: #{inspect(reason)}")
    end

    # Clean up our test key
    case RaBackend.Idempotency.delete_key(user_id, idempotency_key) do
      :ok ->
        IO.puts("✅ SUCCESS: Test key cleaned up successfully")

      {:error, reason} ->
        IO.puts("⚠️  WARNING: Could not clean up test key: #{inspect(reason)}")
    end
  end
end

# Run the test
IdempotencyTest.run()
