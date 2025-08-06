defmodule RaBackend.ImageGen.Providers.Replicate do
  @moduledoc """
  Provider module for Replicate image generation API.
  Supports any Replicate model by building URLs dynamically.
  Now supports both synchronous and asynchronous generation with progress polling.
  """

  require Logger

  @replicate_api "https://api.replicate.com/v1/models"
  @replicate_predictions_api "https://api.replicate.com/v1/predictions"
  @default_wait 60  # seconds (max Replicate allows)
  @poll_interval 2000  # Poll every 2 seconds for progress

  @type media_req :: %{
          model: String.t(),               # "google/imagen-4-fast" or "bytedance/seedance-1-pro"
          input: map(),                    # model-specific input
          wait: pos_integer() | :no_wait | :poll   # optional
        }

  @spec generate_media(media_req()) :: {:ok, map()} | {:error, term()}
  def generate_media(%{model: model, input: input} = params) do
    Logger.info("Starting Replicate media generation with model: #{model}")

    case Map.get(params, :wait, @default_wait) do
      :poll -> generate_media_with_polling(model, input, params)
      wait_mode -> generate_media_sync(model, input, wait_mode)
    end
  end

  # Backward compatibility alias
  def generate_image(params), do: generate_media(params)

  # Synchronous generation (current behavior)
  defp generate_media_sync(model, input, wait_mode) do
    wait_header =
      case wait_mode do
        :no_wait -> nil
        n when is_integer(n) and n > 0 -> {"Prefer", "wait=#{n}"}
        _ -> {"Prefer", "wait"}               # full blocking
      end

    headers =
      [
        {"Authorization", "Bearer #{api_key!()}"},
        {"Content-Type", "application/json"}
      ]
      |> then(fn h -> if wait_header, do: [wait_header | h], else: h end)

    url = "#{@replicate_api}/#{model}/predictions"
    body = Jason.encode!(%{input: input})

    Logger.debug("Making Replicate API call to: #{url}")

    case HTTPoison.post(url, body, headers, recv_timeout: 65_000) do
      {:ok, %HTTPoison.Response{status_code: 201, body: raw_body}} ->
        Logger.info("Replicate generation successful for model: #{model}")
        {:ok, Jason.decode!(raw_body)}

      {:ok, %HTTPoison.Response{status_code: code, body: raw_body}} ->
        Logger.error("Replicate API error: status=#{code}, body=#{raw_body}")
        {:error, %{status: code, body: raw_body, message: "Replicate API error"}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, %{reason: reason, message: "HTTP request failed"}}

      {:error, error} ->
        Logger.error("Unexpected error: #{inspect(error)}")
        {:error, error}
    end
  rescue
    error in Jason.DecodeError ->
      Logger.error("JSON decode error: #{inspect(error)}")
      {:error, %{reason: "Invalid JSON response", details: inspect(error)}}

    error ->
      Logger.error("Unexpected error in generate_image: #{inspect(error)}")
      {:error, %{reason: "Unexpected error", details: inspect(error)}}
  end

  # Asynchronous generation with progress polling
  defp generate_media_with_polling(model, input, params) do
    task_id = Map.get(params, :task_id)
    progress_callback = Map.get(params, :progress_callback)

    Logger.info("Starting async Replicate generation with polling for model: #{model}")

    # Step 1: Create prediction (no wait)
    headers = [
      {"Authorization", "Bearer #{api_key!()}"},
      {"Content-Type", "application/json"}
    ]

    url = "#{@replicate_api}/#{model}/predictions"
    body = Jason.encode!(%{input: input})

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: raw_body}} ->
        case Jason.decode(raw_body) do
          {:ok, prediction} ->
            prediction_id = prediction["id"]
            Logger.info("Created prediction #{prediction_id}, starting polling...")

            # Step 2: Poll for progress
            poll_for_completion(prediction_id, task_id, progress_callback)

          {:error, error} ->
            {:error, %{reason: "JSON decode error", details: inspect(error)}}
        end

      {:ok, %HTTPoison.Response{status_code: code, body: raw_body}} ->
        Logger.error("Replicate API error: status=#{code}, body=#{raw_body}")
        {:error, %{status: code, body: raw_body, message: "Replicate API error"}}

      {:error, error} ->
        Logger.error("Failed to create prediction: #{inspect(error)}")
        {:error, error}
    end
  end

  # Poll Replicate for prediction status and progress
  defp poll_for_completion(prediction_id, task_id, progress_callback, attempt \\ 1) do
    Logger.debug("Polling prediction #{prediction_id}, attempt #{attempt}")

    headers = [{"Authorization", "Bearer #{api_key!()}"}]
    url = "#{@replicate_predictions_api}/#{prediction_id}"

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: raw_body}} ->
        case Jason.decode(raw_body) do
          {:ok, prediction} ->
            status = prediction["status"]
            Logger.debug("Prediction #{prediction_id} status: #{status}")

            # Update progress based on status
            progress = case status do
              "starting" -> 0.2
              "processing" -> 0.6
              "succeeded" -> 1.0
              "failed" -> 0.0
              "canceled" -> 0.0
              _ -> 0.1
            end

            # Call progress callback if provided
            if progress_callback && task_id do
              progress_callback.(task_id, progress)
            end

            case status do
              "succeeded" ->
                Logger.info("Image generation completed for prediction #{prediction_id}")
                {:ok, prediction}

              "failed" ->
                error = prediction["error"] || "Image generation failed"
                Logger.error("Image generation failed for prediction #{prediction_id}: #{error}")
                {:error, %{status: "failed", error: error}}

              "canceled" ->
                Logger.error("Image generation canceled for prediction #{prediction_id}")
                {:error, %{status: "canceled"}}

              status when status in ["starting", "processing"] ->
                # Continue polling
                Process.sleep(@poll_interval)
                poll_for_completion(prediction_id, task_id, progress_callback, attempt + 1)

              _ ->
                Logger.warning("Unknown status #{status} for prediction #{prediction_id}")
                Process.sleep(@poll_interval)
                poll_for_completion(prediction_id, task_id, progress_callback, attempt + 1)
            end

          {:error, error} ->
            {:error, %{reason: "JSON decode error", details: inspect(error)}}
        end

      {:ok, %HTTPoison.Response{status_code: code, body: raw_body}} ->
        Logger.error("Error polling prediction #{prediction_id}: HTTP #{code}, #{raw_body}")
        {:error, %{status: code, body: raw_body}}

      {:error, error} ->
        Logger.error("HTTP error polling prediction #{prediction_id}: #{inspect(error)}")
        {:error, error}
    end
  end

  # Helpers ------------------------------------------------------------
  defp api_key! do
    # Try config first (consistent with other providers), then env var, then error
    case get_config(:replicate) do
      %{api_key: key} when is_binary(key) and key != "" and key != "dummy_key_for_dev" ->
        key
      _ ->
        # Fall back to environment variable for backwards compatibility
        case System.get_env("REPLICATE_API_KEY") do
          key when is_binary(key) and key != "" -> key
          _ -> raise("REPLICATE_API_KEY not configured. Add it to your .env file or config.")
        end
    end
  end

  defp get_config(provider) do
    Application.get_env(:ra_backend, :llm_providers, [])
    |> Keyword.get(provider, %{})
    |> case do
      map when is_map(map) -> map
      list when is_list(list) -> Enum.into(list, %{})
      _ -> %{}
    end
  end
end
