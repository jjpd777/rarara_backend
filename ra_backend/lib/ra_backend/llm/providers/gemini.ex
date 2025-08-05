defmodule RaBackend.LLM.Providers.Gemini do
  @moduledoc "Google Gemini API client implementation"
  @behaviour RaBackend.LLM.LLMService
  require Logger

  alias RaBackend.LLM.LLMService.{Request, Response}
  alias RaBackend.LLM.ProviderHelper

  @impl true
  def generate_text(%Request{prompt: prompt, model: model, options: options, generation_id: generation_id, start_time: start_time}) do
    config = ProviderHelper.get_config(:gemini)

    # Validate configuration
    if config && config[:api_key] do
      headers = [
        {"Content-Type", "application/json"}
      ]

      # Smart token allocation - ensure Gemini gets enough tokens for reliable generation
      user_max_tokens = Map.get(options, "max_tokens")
      smart_max_tokens = ProviderHelper.calculate_smart_tokens(prompt, :gemini, user_max_tokens)
      temperature = Map.get(options, "temperature", 0.7)

      applied_config = %{
        max_tokens: smart_max_tokens,
        temperature: temperature,
        user_requested: user_max_tokens,
        provider_adjusted: smart_max_tokens != user_max_tokens
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
          maxOutputTokens: smart_max_tokens,
          temperature: temperature,
          topP: 0.8,
          topK: 40
        },
        safetySettings: [
          %{
            category: "HARM_CATEGORY_HARASSMENT",
            threshold: "BLOCK_NONE"
          },
          %{
            category: "HARM_CATEGORY_HATE_SPEECH",
            threshold: "BLOCK_NONE"
          },
          %{
            category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            threshold: "BLOCK_NONE"
          },
          %{
            category: "HARM_CATEGORY_DANGEROUS_CONTENT",
            threshold: "BLOCK_NONE"
          }
        ]
      })

      # Fix model resolution and use v1beta API
      url = "https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{config[:api_key]}"

      Logger.debug("Gemini request: model=#{model}, max_tokens=#{smart_max_tokens}, url=#{String.replace(url, config[:api_key] || "", "***")}")

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
      # PRIORITY 1: Check for content first - even if truncated, it's still valid
      %{"content" => %{"parts" => [%{"text" => text} | _]}} when is_binary(text) and text != "" ->
        {:ok, text}

      # PRIORITY 2: Check for content with empty text but MAX_TOKENS (try to extract something)
      %{"content" => %{"parts" => [%{"text" => ""} | _]}, "finishReason" => "MAX_TOKENS"} ->
        {:ok, "[Content too brief for token limit - try simpler prompt or increase max_tokens]"}

      # PRIORITY 3: Handle empty response with MAX_TOKENS - more helpful message
      %{"finishReason" => "MAX_TOKENS"} ->
        {:ok, "[Unable to generate content within token limit - please increase max_tokens or simplify prompt]"}

      # PRIORITY 4: Only error for genuine content blocks
      %{"finishReason" => "SAFETY", "safetyRatings" => ratings} ->
        {:error, "Content blocked by safety filters: #{inspect(ratings)}"}
      %{"finishReason" => "SAFETY"} ->
        {:error, "Content blocked by safety filters"}
      %{"finishReason" => "RECITATION"} ->
        {:error, "Content blocked due to recitation"}

      # PRIORITY 5: Other finish reasons without content
      %{"finishReason" => finish_reason} ->
        {:error, "No content generated: #{finish_reason}"}

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
