defmodule RaBackend.LLM.Providers.Anthropic do
  @moduledoc "Anthropic API client implementation"
  @behaviour RaBackend.LLM.LLMService

  @impl true
  def generate(%{prompt: prompt, model: model, options: options}) do
    config = Application.get_env(:ra_backend, :llm_providers)[:anthropic]

    headers = [
      {"x-api-key", config[:api_key]},
      {"Content-Type", "application/json"},
      {"anthropic-version", "2023-06-01"}
    ]

    body = Jason.encode!(%{
      model: model,
      max_tokens: Map.get(options, :max_tokens, 1000),
      messages: [%{role: "user", content: prompt}]
    })

    case HTTPoison.post("#{config[:base_url]}/messages", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"content" => [%{"text" => content} | _]}} ->
            {:ok, %{
              content: content,
              model: model,
              provider: :anthropic,
              usage: %{},
              finish_reason: "stop",
              raw_response: response_body
            }}
          {:error, _} ->
            {:error, :invalid_response}
        end
      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "HTTP #{status_code}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
