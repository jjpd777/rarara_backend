defmodule RaBackend.LLM.Providers.OpenAI do
  @moduledoc "OpenAI API client implementation"
  @behaviour RaBackend.LLM.LLMService

  @impl true
  def generate(%{prompt: prompt, model: model, options: options}) do
    config = Application.get_env(:ra_backend, :llm_providers)[:openai]

    headers = [
      {"Authorization", "Bearer #{config[:api_key]}"},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(%{
      model: model,
      messages: [%{role: "user", content: prompt}],
      max_tokens: Map.get(options, :max_tokens, 1000),
      temperature: Map.get(options, :temperature, 0.7)
    })

    case HTTPoison.post("#{config[:base_url]}/chat/completions", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
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
