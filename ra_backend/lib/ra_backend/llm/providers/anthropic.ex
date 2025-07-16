defmodule RaBackend.LLM.Providers.Anthropic do
  @moduledoc "Anthropic API client implementation"
  @behaviour RaBackend.LLM.LLMService
  require Logger

  @impl true
  def generate(%{prompt: prompt, model: model, options: options}) do
    config = Application.get_env(:ra_backend, :llm_providers)[:anthropic]

    headers = [
      {"x-api-key", config[:api_key]},
      {"Content-Type", "application/json"},
      {"anthropic-version", "2023-06-01"}
    ]

    # Adjust max_tokens for complex prompts - increased default for longer responses
    max_tokens = Map.get(options, :max_tokens, 2000)

    body = Jason.encode!(%{
      model: model,
      max_tokens: max_tokens,
      messages: [%{role: "user", content: prompt}]
    })

    Logger.debug("Anthropic request: model=#{model}, max_tokens=#{max_tokens}")

    case HTTPoison.post("#{config[:base_url]}/messages", body, headers, timeout: 30_000, recv_timeout: 30_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        handle_success_response(response_body, model)
      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        Logger.error("Anthropic HTTP error #{status_code}: #{error_body}")
        {:error, "HTTP #{status_code}: #{parse_error_message(error_body)}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Anthropic connection error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp handle_success_response(response_body, model) do
    case Jason.decode(response_body) do
      {:ok, %{
        "content" => [%{"text" => content} | _],
        "usage" => usage,
        "stop_reason" => stop_reason
      } = decoded} ->
        {:ok, %{
          content: content,
          model: model,
          provider: :anthropic,
          usage: usage,
          finish_reason: stop_reason,
          raw_response: decoded
        }}
      {:ok, %{"content" => [%{"text" => content} | _]} = decoded} ->
        {:ok, %{
          content: content,
          model: model,
          provider: :anthropic,
          usage: Map.get(decoded, "usage", %{}),
          finish_reason: Map.get(decoded, "stop_reason", "stop"),
          raw_response: decoded
        }}
      {:ok, decoded} ->
        Logger.error("Anthropic unexpected response format: #{inspect(decoded)}")
        {:error, :invalid_response}
      {:error, decode_error} ->
        Logger.error("Anthropic JSON decode error: #{inspect(decode_error)}")
        {:error, :invalid_response}
    end
  end

  defp parse_error_message(error_body) do
    case Jason.decode(error_body) do
      {:ok, %{"error" => %{"message" => message}}} -> message
      {:ok, %{"error" => message}} when is_binary(message) -> message
      _ -> "Unknown error"
    end
  end
end
