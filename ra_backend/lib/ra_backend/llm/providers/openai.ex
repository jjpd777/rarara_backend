defmodule RaBackend.LLM.Providers.OpenAI do
  @moduledoc "OpenAI API client implementation"
  @behaviour RaBackend.LLM.LLMService
  require Logger

  @impl true
  def generate(%{prompt: prompt, model: model, options: options}) do
    config = Application.get_env(:ra_backend, :llm_providers)[:openai]

    headers = [
      {"Authorization", "Bearer #{config[:api_key]}"},
      {"Content-Type", "application/json"}
    ]

    # Adjust max_tokens for complex prompts
    max_tokens = Map.get(options, :max_tokens, 400)

    body = Jason.encode!(%{
      model: model,
      messages: [%{role: "user", content: prompt}],
      max_tokens: max_tokens,
      temperature: Map.get(options, :temperature, 0.7)
    })

    Logger.debug("OpenAI request: model=#{model}, max_tokens=#{max_tokens}")

    case HTTPoison.post("#{config[:base_url]}/chat/completions", body, headers, timeout: 30_000, recv_timeout: 30_000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        handle_success_response(response_body, model)
      {:ok, %HTTPoison.Response{status_code: status_code, body: error_body}} ->
        Logger.error("OpenAI HTTP error #{status_code}: #{error_body}")
        {:error, "HTTP #{status_code}: #{parse_error_message(error_body)}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("OpenAI connection error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp handle_success_response(response_body, model) do
    case Jason.decode(response_body) do
      {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _] = choices, "usage" => usage}} ->
        {:ok, %{
          content: content,
          model: model,
          provider: :openai,
          usage: usage,
          finish_reason: Map.get(List.first(choices), "finish_reason", "stop"),
          raw_response: choices
        }}
      {:ok, decoded} ->
        Logger.error("OpenAI unexpected response format: #{inspect(decoded)}")
        {:error, :invalid_response}
      {:error, decode_error} ->
        Logger.error("OpenAI JSON decode error: #{inspect(decode_error)}")
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
