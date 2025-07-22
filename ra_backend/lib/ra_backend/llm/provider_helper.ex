defmodule RaBackend.LLM.ProviderHelper do
  @moduledoc "Helper module for LLM providers"
  require Logger

  def get_config(provider) do
    Application.get_env(:ra_backend, :llm_providers)[provider]
  end

  def handle_http_error(%HTTPoison.Response{status_code: status_code, body: error_body}, provider) do
    Logger.error("#{provider} HTTP error #{status_code}: #{error_body}")
    {:error, "HTTP #{status_code}: #{parse_error_message(error_body)}"}
  end

  def handle_http_error(%HTTPoison.Error{reason: reason}, provider) do
    Logger.error("#{provider} connection error: #{inspect(reason)}")
    {:error, reason}
  end

  defp parse_error_message(error_body) do
    case Jason.decode(error_body) do
      {:ok, %{"error" => %{"message" => message}}} -> message
      {:ok, %{"error" => message}} when is_binary(message) -> message
      _ -> "Unknown error"
    end
  end
end
