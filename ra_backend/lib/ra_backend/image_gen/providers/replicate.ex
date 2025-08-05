defmodule RaBackend.ImageGen.Providers.Replicate do
  @moduledoc """
  Provider module for Replicate image generation API.
  Supports any Replicate model by building URLs dynamically.
  """

  require Logger

  @replicate_api "https://api.replicate.com/v1/models"
  @default_wait 60  # seconds (max Replicate allows)

  @type image_req :: %{
          model: String.t(),               # "google/imagen-4-fast"
          input: map(),                    # model-specific input
          wait: pos_integer() | :no_wait   # optional
        }

  @spec generate_image(image_req()) :: {:ok, map()} | {:error, term()}
  def generate_image(%{model: model, input: input} = params) do
    Logger.info("Starting Replicate image generation with model: #{model}")

    wait_header =
      case Map.get(params, :wait, @default_wait) do
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
