defmodule RaBackend.LLM.Providers.Gemini do
  @moduledoc "Google Gemini API client implementation"
  @behaviour RaBackend.LLM.LLMService

  @impl true
  def generate(%{prompt: prompt, model: model, options: options}) do
    config = Application.get_env(:ra_backend, :llm_providers)[:gemini]

    headers = [
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(%{
      contents: [%{
        parts: [%{text: prompt}]
      }],
      generationConfig: %{
        maxOutputTokens: Map.get(options, :max_tokens, 1000),
        temperature: Map.get(options, :temperature, 0.7)
      }
    })

    url = "#{config[:base_url]}/models/#{model}:generateContent?key=#{config[:api_key]}"

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"text" => content} | _]}} | _]}} ->
            {:ok, %{
              content: content,
              model: model,
              provider: :gemini,
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
