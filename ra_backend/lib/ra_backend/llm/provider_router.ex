defmodule RaBackend.LLM.ProviderRouter do
  @moduledoc "Routes requests to appropriate LLM provider based on model name"
  require Logger
  alias RaBackend.LLM.LLMService.Request
  alias RaBackend.LLM.ModelRegistry

  def route_request(%Request{model: model} = request) do
    case ModelRegistry.find_provider_by_model(model) do
      {:ok, provider} ->
        provider.generate(request)
      {:error, :unsupported_model} ->
        {:error, :unsupported_model}
    end
  end

  def route_request_with_retry(request, max_retries \\ 2) do
    # Generate unique ID and add timing
    generation_id = generate_request_id()
    start_time = System.monotonic_time(:millisecond)

    enriched_request = %Request{
      request |
      generation_id: generation_id,
      start_time: start_time
    }

    do_request_with_retry(enriched_request, max_retries, 0)
  end

  defp do_request_with_retry(request, max_retries, attempt) do
    Logger.info("LLM attempt #{attempt + 1}/#{max_retries + 1} for model: #{request.model} [#{request.generation_id}]")

    case route_request(request) do
      {:ok, response} ->
        # Enrich response with attempt metadata
        enriched_response = %{
          response |
          request_metadata: Map.merge(response.request_metadata || %{}, %{
            attempt_number: attempt + 1,
            retry_count: attempt,
            total_attempts: max_retries + 1
          })
        }
        {:ok, enriched_response}
      {:error, reason} when attempt < max_retries ->
        Logger.warning("LLM attempt #{attempt + 1} failed: #{inspect(reason)}, retrying... [#{request.generation_id}]")
        :timer.sleep(1000 * (attempt + 1))  # Exponential backoff
        do_request_with_retry(request, max_retries, attempt + 1)
      {:error, reason} ->
        Logger.error("LLM failed after #{attempt + 1} attempts: #{inspect(reason)} [#{request.generation_id}]")
        {:error, %{
          reason: reason,
          generation_id: request.generation_id,
          attempt_number: attempt + 1,
          retry_count: attempt,
          total_attempts: max_retries + 1
        }}
    end
  end

  defp generate_request_id do
    "req_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end
end
