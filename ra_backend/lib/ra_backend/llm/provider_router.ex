defmodule RaBackend.LLM.ProviderRouter do
  @moduledoc "Routes requests to appropriate LLM provider based on model name"
  require Logger

  def route_request(%{model: model} = request) do
    cond do
      String.starts_with?(model, "gpt-") ->
        RaBackend.LLM.Providers.OpenAI.generate(request)
      String.starts_with?(model, "claude-") ->
        RaBackend.LLM.Providers.Anthropic.generate(request)
      String.starts_with?(model, "gemini-") ->
        RaBackend.LLM.Providers.Gemini.generate(request)
      true ->
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
        Logger.warn("LLM attempt #{attempt + 1} failed: #{inspect(reason)}, retrying...")
        :timer.sleep(1000 * (attempt + 1))  # Exponential backoff
        do_request_with_retry(request, max_retries, attempt + 1)
      {:error, reason} ->
        Logger.error("LLM failed after #{attempt + 1} attempts: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
