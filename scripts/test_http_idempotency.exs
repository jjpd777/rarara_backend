# Test HTTP idempotency through the API endpoint
# This requires the server to be running

defmodule HTTPIdempotencyTest do
  def run do
    IO.puts("🌐 Testing HTTP Idempotency via API Endpoint")
    IO.puts("=" |> String.duplicate(45))

    # Test data
    user_id = "11111111-1111-1111-1111-111111111111"
    idempotency_key = "test-http-#{System.unique_integer([:positive])}"

    payload = %{
      "input_data" => %{
        "type" => "video",
        "prompt" => "A magical forest with glowing trees",
        "duration" => 5
      }
    }

    headers = [
      {"Content-Type", "application/json"},
      {"X-User-ID", user_id},
      {"Idempotency-Key", idempotency_key}
    ]

    url = "http://localhost:4000/api/tasks"

    IO.puts("\n📋 Test 1: First video request with idempotency key")

    # First request
    case make_request(url, payload, headers) do
      {:ok, response1} ->
        IO.puts("✅ SUCCESS: First request completed")
        IO.puts("   Status: #{response1.status_code}")
        IO.puts("   Body: #{response1.body}")

        # Parse response to get task_id
        case Jason.decode(response1.body) do
          {:ok, %{"data" => %{"task_id" => task_id1}}} ->
            IO.puts("   Task ID: #{task_id1}")

            IO.puts("\n📋 Test 2: Duplicate request with same idempotency key")

            # Second request with same idempotency key
            case make_request(url, payload, headers) do
              {:ok, response2} ->
                IO.puts("✅ SUCCESS: Second request completed")
                IO.puts("   Status: #{response2.status_code}")

                case Jason.decode(response2.body) do
                  {:ok, %{"data" => %{"task_id" => task_id2}}} ->
                    if task_id1 == task_id2 do
                      IO.puts("✅ SUCCESS: Same task ID returned (#{task_id2})")
                    else
                      IO.puts("❌ FAIL: Different task ID returned")
                      IO.puts("   First: #{task_id1}")
                      IO.puts("   Second: #{task_id2}")
                    end

                  {:ok, parsed} ->
                    IO.puts("   Response: #{inspect(parsed)}")

                  {:error, _} ->
                    IO.puts("   Raw response: #{response2.body}")
                end

              {:error, reason} ->
                IO.puts("❌ FAIL: Second request failed: #{inspect(reason)}")
            end

          {:ok, parsed} ->
            IO.puts("   Response: #{inspect(parsed)}")

          {:error, _} ->
            IO.puts("   Raw response: #{response1.body}")
        end

      {:error, reason} ->
        IO.puts("❌ FAIL: First request failed: #{inspect(reason)}")
        IO.puts("   Make sure the server is running: mix phx.server")
    end

    IO.puts("\n📋 Test 3: Different request (should create new task)")

    different_payload = %{
      "input_data" => %{
        "type" => "video",
        "prompt" => "A spaceship landing on Mars",
        "duration" => 5
      }
    }

    different_headers = [
      {"Content-Type", "application/json"},
      {"X-User-ID", user_id},
      {"Idempotency-Key", "different-key-#{System.unique_integer([:positive])}"}
    ]

    case make_request(url, different_payload, different_headers) do
      {:ok, response} ->
        IO.puts("✅ SUCCESS: Different request completed")
        IO.puts("   Status: #{response.status_code}")

        case Jason.decode(response.body) do
          {:ok, %{"data" => %{"task_id" => new_task_id}}} ->
            IO.puts("   New Task ID: #{new_task_id}")

          {:ok, parsed} ->
            IO.puts("   Response: #{inspect(parsed)}")

          {:error, _} ->
            IO.puts("   Raw response: #{response.body}")
        end

      {:error, reason} ->
        IO.puts("❌ FAIL: Different request failed: #{inspect(reason)}")
    end

    IO.puts("\n✅ HTTP Idempotency tests completed!")
  end

  defp make_request(url, payload, headers) do
    body = Jason.encode!(payload)

    case HTTPoison.post(url, body, headers) do
      {:ok, response} -> {:ok, response}
      {:error, %HTTPoison.Error{reason: :econnrefused}} ->
        {:error, "Server not running. Start with: mix phx.server"}
      {:error, error} -> {:error, error}
    end
  end
end

HTTPIdempotencyTest.run()
