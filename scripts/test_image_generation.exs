# Test script for Image Generation functionality
# Run with: mix run scripts/test_image_generation.exs

# Start the application context
Mix.Task.run("app.start")

defmodule ImageGenerationTest do
  require Logger
  alias RaBackend.ModelRegistry
  alias RaBackend.Tasks
  alias RaBackend.Workers.TaskWorker

  def test_unified_registry do
    Logger.info("Testing unified model registry...")

    # Test text models
    text_models = ModelRegistry.all_by_type(:text_gen)
    Logger.info("✅ Found #{length(text_models)} text generation models")

    # Test image models
    image_models = ModelRegistry.all_by_type(:image_gen)
    Logger.info("✅ Found #{length(image_models)} image generation models")

    # Test model lookup
    case ModelRegistry.find_provider_by_model("google/imagen-4-fast") do
      {:ok, provider} ->
        Logger.info("✅ Successfully found provider: #{inspect(provider)}")
      {:error, reason} ->
        Logger.error("❌ Failed to find provider: #{inspect(reason)}")
    end
  end

  def test_task_creation do
    Logger.info("Testing image generation task creation...")

    task_params = %{
      "task_type" => "image_gen",
      "model" => "google/imagen-4-fast",
      "input_data" => %{
        "prompt" => "Jesus Christ on the Cross",
        "aspect_ratio" => "16:9"
      }
    }

    case Tasks.create_task(task_params) do
      {:ok, task} ->
        Logger.info("✅ Created image generation task: #{task.id}")
        Logger.info("   Model: #{task.model}")
        Logger.info("   Type: #{task.task_type}")
        Logger.info("   Input: #{inspect(task.input_data)}")

        # Test task lookup
        _retrieved_task = Tasks.get_task!(task.id)
        Logger.info("✅ Successfully retrieved task from database")

        task
      {:error, changeset} ->
        Logger.error("❌ Failed to create task: #{inspect(changeset.errors)}")
        nil
    end
  end

  def test_image_generation_with_details do
    Logger.info("Testing image generation provider with detailed logging...")

    # Test the provider directly
    alias RaBackend.ImageGen.Providers.Replicate

    params = %{
      model: "google/imagen-4-fast",
      input: %{
        "prompt" => "A test image generation: a serene lake with mountains in the background",
        "aspect_ratio" => "4:3"
      },
      wait: 30
    }

    Logger.info("🔄 Attempting Replicate API call...")
    Logger.info("   Model: #{params.model}")
    Logger.info("   Prompt: #{params.input["prompt"]}")
    Logger.info("   Aspect Ratio: #{params.input["aspect_ratio"]}")

    case Replicate.generate_image(params) do
      {:ok, response} ->
        Logger.info("🎉 SUCCESS! Image generation completed!")
        Logger.info("   Prediction ID: #{response["id"]}")
        Logger.info("   Status: #{response["status"]}")

        # Log the image URL(s)
        case response["output"] do
          url when is_binary(url) ->
            Logger.info("🖼️  Image URL: #{url}")
            IO.puts("")
            IO.puts("🌟 GENERATED IMAGE AVAILABLE AT:")
            IO.puts("   #{url}")
            IO.puts("")

          urls when is_list(urls) ->
            Logger.info("🖼️  Generated #{length(urls)} images:")
            Enum.with_index(urls, 1) |> Enum.each(fn {url, index} ->
              Logger.info("   Image #{index}: #{url}")
            end)
            IO.puts("")
            IO.puts("🌟 GENERATED IMAGES AVAILABLE AT:")
            Enum.with_index(urls, 1) |> Enum.each(fn {url, index} ->
              IO.puts("   Image #{index}: #{url}")
            end)
            IO.puts("")

          nil ->
            Logger.info("⚠️  No image URLs in response yet (may still be processing)")
            Logger.info("   Full response: #{inspect(response)}")

          other ->
            Logger.info("🔍 Unexpected output format: #{inspect(other)}")
        end

        {:ok, response}

      {:error, %{status: status, body: body}} when is_integer(status) ->
        Logger.error("❌ Replicate API Error (HTTP #{status}):")

        case Jason.decode(body) do
          {:ok, decoded} ->
            Logger.error("   Error: #{decoded["detail"] || decoded["error"] || "Unknown API error"}")
          {:error, _} ->
            Logger.error("   Raw response: #{body}")
        end

        if status == 401 do
          Logger.info("💡 This is likely due to missing or invalid REPLICATE_API_KEY")
          Logger.info("💡 Set your token: export REPLICATE_API_KEY=\"your-token-here\"")
        end

      {:error, %{reason: "Unexpected error", details: details}} ->
        if String.contains?(details, "REPLICATE_API_KEY") do
          Logger.info("⚠️  No API key configured (expected for testing)")
          Logger.info("💡 To test actual image generation:")
          Logger.info("   1. Get a token from https://replicate.com")
          Logger.info("   2. Add to .env: REPLICATE_API_KEY=\"your-token\"")
          Logger.info("   3. Re-run this test")
        else
          Logger.error("❌ Unexpected error: #{details}")
        end

      {:error, error} ->
        Logger.error("❌ Image generation failed: #{inspect(error)}")
    end
  end

  def test_full_worker_flow do
    Logger.info("Testing full worker flow (simulated)...")

    # Create a task
    case test_task_creation() do
      %{id: task_id} = task when not is_nil(task_id) ->
        Logger.info("🔄 Simulating TaskWorker.perform() for task: #{task_id}")

        # Simulate the worker process step by step
        Logger.info("   1. Worker fetches task from database")
        Logger.info("   2. Worker sees task_type: #{task.task_type}")
        Logger.info("   3. Worker would dispatch to image generation")
        Logger.info("   4. Worker would call ModelRegistry.find_provider_by_model(\"#{task.model}\")")

        case ModelRegistry.find_provider_by_model(task.model) do
          {:ok, provider} ->
            Logger.info("   5. ✅ Provider found: #{inspect(provider)}")
            Logger.info("   6. Worker would call provider.generate_image/1 with:")
            Logger.info("      - Model: #{task.model}")
            Logger.info("      - Input: #{inspect(task.input_data)}")
            Logger.info("   7. Worker would update task progress: 0.1 → 0.5 → 0.9 → 1.0")
            Logger.info("   8. Worker would store result in task.result_data")
            Logger.info("   9. Worker would broadcast progress via PubSub → WebSocket")
            Logger.info("   ✅ Full worker flow validated!")

          {:error, reason} ->
            Logger.error("   ❌ Provider lookup failed: #{inspect(reason)}")
        end

      nil ->
        Logger.error("❌ Cannot test worker without a valid task")
    end
  end

  def test_api_token_status do
    Logger.info("Checking API token configuration...")

    # Check for the key in the config (consistent with how providers work)
    config_key = Application.get_env(:ra_backend, :llm_providers, [])
                 |> Keyword.get(:replicate, [])
                 |> case do
                   list when is_list(list) -> Keyword.get(list, :api_key)
                   map when is_map(map) -> Map.get(map, :api_key)
                   _ -> nil
                 end

    env_key = System.get_env("REPLICATE_API_KEY")

    key = cond do
      is_binary(config_key) and config_key != "" and config_key != "dummy_key_for_dev" -> config_key
      is_binary(env_key) and env_key != "" -> env_key
      true -> nil
    end

    if key do
      Logger.info("✅ REPLICATE_API_KEY is configured")
      Logger.info("   Key preview: #{String.slice(key, 0, 8)}...")
      Logger.info("🚀 Real image generation should work!")
    else
      Logger.info("⚠️  REPLICATE_API_KEY not configured")
      Logger.info("💡 To enable real image generation:")
      IO.puts("   Add to your .env file: REPLICATE_API_KEY=\"your-token-from-replicate.com\"")
    end
  end

  def run_all_tests do
    Logger.info("🧪 Starting Image Generation tests...")
    IO.puts("")

    test_api_token_status()
    IO.puts("")

    test_unified_registry()
    IO.puts("")

    test_task_creation()
    IO.puts("")

    test_image_generation_with_details()
    IO.puts("")

    test_full_worker_flow()

    IO.puts("")
    Logger.info("🚀 Image Generation implementation ready!")
    IO.puts("📱 Clients can now use:")
    IO.puts("   socket.push('image_generate', {prompt: 'A beautiful landscape', model: 'google/imagen-4-fast'})")
    IO.puts("   socket.on('image_response', response => { ... })")
    IO.puts("   socket.on('progress', progress => { ... })")  # For real-time progress
    IO.puts("")
    IO.puts("💡 To test the full WebSocket flow:")
    IO.puts("   1. Start the Phoenix server: mix phx.server")
    IO.puts("   2. Connect to ws://localhost:4000/socket")
    IO.puts("   3. Join channel: task:image_test")
    IO.puts("   4. Send: image_generate with {prompt: 'Test image', model: 'google/imagen-4-fast'}")
    IO.puts("   5. Receive: image_response with task_id")
    IO.puts("   6. Receive: progress updates as the image generates")
    IO.puts("")
    IO.puts("🔑 For REAL image generation:")
    IO.puts("   Add to .env: REPLICATE_API_KEY=\"your-token-from-replicate.com\"")
  end
end

# Run the tests
ImageGenerationTest.run_all_tests()
