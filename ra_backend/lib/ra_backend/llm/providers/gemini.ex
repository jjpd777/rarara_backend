defmodule RaBackend.LLM.Providers.Gemini do
  @moduledoc "Google Gemini API client implementation"
  @behaviour RaBackend.LLM.LLMService
  require Logger

  alias RaBackend.LLM.LLMService.{Request, Response}
  alias RaBackend.LLM.ProviderHelper

  @impl true
  def generate(%Request{prompt: prompt, model: model, options: options, generation_id: generation_id, start_time: start_time}) do
    config = ProviderHelper.get_config(:gemini)

    # Validate configuration
    if config && config[:api_key] do
      headers = [
        {"Content-Type", "application/json"}
      ]

      # Apply defaults and capture what's actually used
      max_tokens = Map.get(options, "max_tokens", 2000)
      temperature = Map.get(options, "temperature", 0.7)

      applied_config = %{
        max_tokens: max_tokens,
        temperature: temperature
      }

      body = Jason.encode!(%{
        contents: [
          %{
            parts: [
              %{text: prompt}
            ]
          }
        ],
        generationConfig: %{
          maxOutputTokens: max_tokens,
          temperature: temperature,
          topP: 0.8,
          topK: 40
        },
        safetySettings: [
          %{
            category: "HARM_CATEGORY_HARASSMENT",
            threshold: "BLOCK_ONLY_HIGH"
          },
          %{
            category: "HARM_CATEGORY_HATE_SPEECH",
            threshold: "BLOCK_ONLY_HIGH"
          },
          %{
            category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            threshold: "BLOCK_ONLY_HIGH"
          },
          %{
            category: "HARM_CATEGORY_DANGEROUS_CONTENT",
            threshold: "BLOCK_ONLY_HIGH"
          }
        ]
      })

      # Fix model resolution and use v1 API
      url = "https://generativelanguage.googleapis.com/v1/models/#{model}:generateContent?key=#{config[:api_key]}"

      Logger.debug("Gemini request: model=#{model}, max_tokens=#{max_tokens}, url=#{String.replace(url, config[:api_key] || "", "***")}")

      provider_start = System.monotonic_time(:millisecond)

      case HTTPoison.post(url, body, headers, timeout: 30_000, recv_timeout: 30_000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
          provider_end = System.monotonic_time(:millisecond)
          handle_success_response(response_body, model, generation_id, applied_config, start_time, provider_start, provider_end)
        {:ok, error} ->
          ProviderHelper.handle_http_error(error, "Gemini")
        {:error, error} ->
          ProviderHelper.handle_http_error(error, "Gemini")
      end
    else
      Logger.error("Gemini configuration missing or invalid")
      {:error, "Gemini API key not configured"}
    end
  end

  defp handle_success_response(response_body, model, generation_id, applied_config, start_time, provider_start, provider_end) do
    case Jason.decode(response_body) do
      {:ok, %{"candidates" => [candidate | _]} = decoded} ->
        case extract_content(candidate) do
          {:ok, content} ->
            total_time = if start_time, do: System.monotonic_time(:millisecond) - start_time, else: nil
            provider_time = provider_end - provider_start

            {:ok, %Response{
              content: content,
              model: model,
              provider: :gemini,
              usage: Map.get(decoded, "usageMetadata", %{}),
              finish_reason: Map.get(candidate, "finishReason", "STOP"),
              raw_response: decoded,
              generation_id: generation_id,
              applied_config: applied_config,
              timing_info: %{
                total_ms: total_time,
                provider_ms: provider_time
              },
              request_metadata: %{
                provider: :gemini,
                timestamp: DateTime.utc_now()
              }
            }}
          {:error, reason} ->
            Logger.error("Gemini content extraction failed: #{inspect(reason)}, candidate: #{inspect(candidate)}")
            {:error, "Content blocked or unavailable: #{reason}"}
        end
      {:ok, %{"error" => error}} ->
        Logger.error("Gemini API error in success response: #{inspect(error)}")
        {:error, parse_error_from_response(error)}
      {:ok, decoded} ->
        Logger.error("Gemini unexpected response format: #{inspect(decoded)}")
        {:error, "Invalid response format"}
      {:error, decode_error} ->
        Logger.error("Gemini JSON decode error: #{inspect(decode_error)}, body: #{response_body}")
        {:error, :invalid_response}
    end
  end

  defp extract_content(candidate) do
    case candidate do
      %{"content" => %{"parts" => [%{"text" => text} | _]}} when is_binary(text) and text != "" ->
        {:ok, text}
      %{"finishReason" => "SAFETY"} ->
        {:error, "Content blocked by safety filters"}
      %{"finishReason" => "RECITATION"} ->
        {:error, "Content blocked due to recitation"}
      %{"finishReason" => finish_reason} ->
        {:error, "Generation stopped: #{finish_reason}"}
      _ ->
        {:error, "No valid text content found"}
    end
  end

  defp parse_error_from_response(error) when is_map(error) do
    case error do
      %{"message" => message} -> message
      %{"status" => status, "message" => message} -> "#{status}: #{message}"
      _ -> "API error: #{inspect(error)}"
    end
  end
  defp parse_error_from_response(error), do: "API error: #{inspect(error)}"
end
