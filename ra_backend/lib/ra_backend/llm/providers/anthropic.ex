defmodule RaBackend.LLM.Providers.Anthropic do
  @moduledoc "Anthropic API client implementation"
  @behaviour RaBackend.LLM.LLMService
  require Logger

  alias RaBackend.LLM.LLMService.{Request, Response}
  alias RaBackend.LLM.ProviderHelper

  @impl true
  def generate(%Request{prompt: prompt, model: model, options: options, generation_id: generation_id, start_time: start_time}) do
    config = ProviderHelper.get_config(:anthropic)

    # Validate configuration
    if config && config[:api_key] && config[:base_url] do
      headers = [
        {"x-api-key", config[:api_key]},
        {"Content-Type", "application/json"},
        {"anthropic-version", "2023-06-01"}
      ]

      # Smart token allocation - ensure consistent behavior with other providers
      user_max_tokens = Map.get(options, "max_tokens")
      smart_max_tokens = ProviderHelper.calculate_smart_tokens(prompt, :anthropic, user_max_tokens)
      temperature = Map.get(options, "temperature", 0.7)

      applied_config = %{
        max_tokens: smart_max_tokens,
        temperature: temperature,
        user_requested: user_max_tokens,
        provider_adjusted: smart_max_tokens != user_max_tokens
      }

      body = Jason.encode!(%{
        model: model,
        max_tokens: smart_max_tokens,
        messages: [%{role: "user", content: prompt}]
      })

      Logger.debug("Anthropic request: model=#{model}, max_tokens=#{smart_max_tokens}")

      provider_start = System.monotonic_time(:millisecond)

      case HTTPoison.post("#{config[:base_url]}/messages", body, headers, timeout: 30_000, recv_timeout: 30_000) do
        {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
          provider_end = System.monotonic_time(:millisecond)
          handle_success_response(response_body, model, generation_id, applied_config, start_time, provider_start, provider_end)
        {:ok, error} ->
          ProviderHelper.handle_http_error(error, "Anthropic")
        {:error, error} ->
          ProviderHelper.handle_http_error(error, "Anthropic")
      end
    else
      Logger.error("Anthropic configuration missing or invalid")
      {:error, "Anthropic API key or base URL not configured"}
    end
  end

  defp handle_success_response(response_body, model, generation_id, applied_config, start_time, provider_start, provider_end) do
    case Jason.decode(response_body) do
      {:ok, %{
        "content" => [%{"text" => content} | _],
        "usage" => usage,
        "stop_reason" => stop_reason
      } = decoded} ->
        total_time = if start_time, do: System.monotonic_time(:millisecond) - start_time, else: nil
        provider_time = provider_end - provider_start

        {:ok, %Response{
          content: content,
          model: model,
          provider: :anthropic,
          usage: usage,
          finish_reason: stop_reason,
          raw_response: decoded,
          generation_id: generation_id,
          applied_config: applied_config,
          timing_info: %{
            total_ms: total_time,
            provider_ms: provider_time
          },
          request_metadata: %{
            provider: :anthropic,
            timestamp: DateTime.utc_now()
          }
        }}
      {:ok, %{"content" => [%{"text" => content} | _]} = decoded} ->
        total_time = if start_time, do: System.monotonic_time(:millisecond) - start_time, else: nil
        provider_time = provider_end - provider_start

        {:ok, %Response{
          content: content,
          model: model,
          provider: :anthropic,
          usage: Map.get(decoded, "usage", %{}),
          finish_reason: Map.get(decoded, "stop_reason", "stop"),
          raw_response: decoded,
          generation_id: generation_id,
          applied_config: applied_config,
          timing_info: %{
            total_ms: total_time,
            provider_ms: provider_time
          },
          request_metadata: %{
            provider: :anthropic,
            timestamp: DateTime.utc_now()
          }
        }}
      {:ok, decoded} ->
        Logger.error("Anthropic unexpected response format: #{inspect(decoded)}")
        {:error, :invalid_response}
      {:error, decode_error} ->
        Logger.error("Anthropic JSON decode error: #{inspect(decode_error)}")
        {:error, :invalid_response}
    end
  end
end
