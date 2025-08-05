defmodule RaBackend.LLM.ProviderRouter do
  @moduledoc """
  Routes LLM requests to the appropriate provider based on the model.
  """

  alias RaBackend.ModelRegistry

  require Logger

  @doc """
  Routes a request to the appropriate provider with retry logic.
  """
  def route_request_with_retry(request, max_retries \\ 3, delay_ms \\ 1000) do
    Logger.debug("Routing LLM request: model=#{request.model}")

    case route_request(request) do
      {:ok, response} ->
        {:ok, response}
      {:error, reason} ->
        if max_retries > 0 do
          Logger.warning("LLM request failed, retrying in #{delay_ms}ms. Retries left: #{max_retries - 1}")
          Process.sleep(delay_ms)
          route_request_with_retry(request, max_retries - 1, delay_ms * 2)  # Exponential backoff
        else
          Logger.error("LLM request failed after all retries: #{inspect(reason)}")
          {:error, reason}
        end
    end
  end

  @doc """
  Routes a request to the appropriate provider.
  """
  def route_request(request) do
    with {:ok, provider} <- ModelRegistry.find_provider_by_model(request.model),
         {:ok, response} <- provider.generate_text(request) do
      Logger.debug("LLM generation successful: provider=#{inspect(provider)}")
      {:ok, response}
    else
      {:error, :unsupported_model} ->
        Logger.error("Unsupported model: #{request.model}")
        {:error, %{reason: "Unsupported model: #{request.model}"}}

      {:error, reason} ->
        Logger.error("LLM generation failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Gets all available models for the API.
  """
  def get_models_for_api do
    ModelRegistry.all_by_type(:text_gen)
    |> Enum.map(&Map.drop(&1, [:provider]))
  end
end
