defmodule RaBackend.LLM.Providers.Gemini do
  @moduledoc "Google Gemini API client implementation"
  @behaviour RaBackend.LLM.LLMService

  @impl true
  def generate(%{prompt: prompt, options: options}) do
    config = Application.get_env(:ra_backend, :llm_providers)[:gemini]

    headers = [
      {"Content-Type", "application/json"},
      {"x-goog-api-key", config[:api_key]}
    ]

    body = Jason.encode!(%{
      contents: [
        %{
          parts: [
            %{text: prompt}
          ]
        }
      ],
      generationConfig: %{
        maxOutputTokens: Map.get(options, :max_tokens, 1000),
        temperature: Map.get(options, :temperature, 0.7)
      }
    })

    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"candidates" => [candidate | _], "usageMetadata" => usage}} ->
            content =
              case candidate do
                %{"content" => %{"parts" => [%{"text" => text} | _]}} -> text
                _ -> "No text content returned."
              end

            {:ok, %{
              content: content,
              model: "gemini-2.5-flash",
              provider: :gemini,
              usage: usage,
              finish_reason: Map.get(candidate, "finishReason", "unknown"),
              raw_response: Jason.decode!(response_body)
            }}

          {:ok, decoded} ->
            {:ok, %{
              content: "No text content returned.",
              model: "gemini-2.5-flash",
              provider: :gemini,
              usage: Map.get(decoded, "usageMetadata", %{}),
              finish_reason: "unknown",
              raw_response: decoded
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
