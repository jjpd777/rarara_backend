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
    do_request_with_retry(request, max_retries, 0)
  end

  defp do_request_with_retry(request, max_retries, attempt) do
    Logger.info("LLM attempt #{attempt + 1}/#{max_retries + 1} for model: #{request.model}")

    case route_request(request) do
      {:ok, response} ->
        {:ok, response}
      {:error, reason} when attempt < max_retries ->
        Logger.warning("LLM attempt #{attempt + 1} failed: #{inspect(reason)}, retrying...")
        :timer.sleep(1000 * (attempt + 1))  # Exponential backoff
        do_request_with_retry(request, max_retries, attempt + 1)
      {:error, reason} ->
        Logger.error("LLM failed after #{attempt + 1} attempts: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
