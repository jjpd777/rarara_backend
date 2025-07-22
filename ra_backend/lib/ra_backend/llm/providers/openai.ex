defmodule RaBackend.LLM.Providers.OpenAI do
  @moduledoc "OpenAI API client implementation"
  @behaviour RaBackend.LLM.LLMService
  require Logger

  alias RaBackend.LLM.LLMService.{Request, Response}
  alias RaBackend.LLM.ProviderHelper

  @impl true
  def generate(%Request{prompt: prompt, model: model, options: options}) do
    config = ProviderHelper.get_config(:openai)

    # Validate configuration
    if config && config[:api_key] && config[:base_url] do
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
        {:ok, error} ->
          ProviderHelper.handle_http_error(error, "OpenAI")
        {:error, error} ->
          ProviderHelper.handle_http_error(error, "OpenAI")
      end
    else
      Logger.error("OpenAI configuration missing or invalid")
      {:error, "OpenAI API key or base URL not configured"}
    end
  end

  defp handle_success_response(response_body, model) do
    case Jason.decode(response_body) do
      {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _] = choices, "usage" => usage}} ->
        {:ok, %Response{
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
end
