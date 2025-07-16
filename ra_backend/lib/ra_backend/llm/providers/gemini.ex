defmodule RaBackend.LLM.Providers.Gemini do
  @moduledoc "Google Gemini API client implementation"
  @behaviour RaBackend.LLM.LLMService
  require Logger

  @impl true
  def generate(%{prompt: prompt, model: model, options: options}) do
    config = Application.get_env(:ra_backend, :llm_providers)[:gemini]

    headers = [
      {"Content-Type", "application/json"}
    ]

    # Add API key to URL instead of header for better compatibility
    max_tokens = Map.get(options, :max_tokens, 2000)

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
        temperature: Map.get(options, :temperature, 0.7),
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

    Logger.debug("Gemini request: model=#{model}, max_tokens=#{max_tokens}, url=#{String.replace(url, config[:api_key], "***")}")

    case HTTPoison.post(url, body, headers, timeout: 30_000, recv_timeout: 30_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        handle_success_response(response_body, model)
      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        Logger.error("Gemini HTTP error #{status_code}: #{error_body}")
        {:error, "HTTP #{status_code}: #{parse_error_message(error_body)}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Gemini connection error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp handle_success_response(response_body, model) do
    case Jason.decode(response_body) do
      {:ok, %{"candidates" => [candidate | _]} = decoded} ->
        case extract_content(candidate) do
          {:ok, content} ->
            {:ok, %{
              content: content,
              model: model,
              provider: :gemini,
              usage: Map.get(decoded, "usageMetadata", %{}),
              finish_reason: Map.get(candidate, "finishReason", "STOP"),
              raw_response: decoded
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

  defp parse_error_message(error_body) do
    case Jason.decode(error_body) do
      {:ok, %{"error" => %{"message" => message}}} -> message
      {:ok, %{"error" => %{"status" => status, "message" => message}}} -> "#{status}: #{message}"
      {:ok, %{"error" => message}} when is_binary(message) -> message
      _ -> "Unknown error"
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
