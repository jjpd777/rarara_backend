defmodule RaBackend.LLM.ProviderHelper do
  @moduledoc "Helper module for LLM providers"
  require Logger

  def get_config(provider) do
    case Application.get_env(:ra_backend, :llm_providers) do
      nil ->
        Logger.error("No LLM providers configured")
        nil
      providers when is_list(providers) ->
        providers[provider]
      _ ->
        Logger.error("Invalid LLM providers configuration")
        nil
    end
  end

  def handle_http_error(%HTTPoison.Response{status_code: status_code, body: error_body}, provider) do
    Logger.error("#{provider} HTTP error #{status_code}: #{error_body}")
    {:error, "HTTP #{status_code}: #{parse_error_message(error_body)}"}
  end

  def handle_http_error(%HTTPoison.Error{reason: reason}, provider) do
    Logger.error("#{provider} connection error: #{inspect(reason)}")
    {:error, reason}
  end

  @doc """
  Normalizes token usage data from different providers into a consistent format.
  Returns a map with input, output, and total token counts.
  """
  def normalize_tokens(usage) when is_map(usage) do
    cond do
      # OpenAI format
      Map.has_key?(usage, "prompt_tokens") ->
        %{
          input: Map.get(usage, "prompt_tokens", 0),
          output: Map.get(usage, "completion_tokens", 0),
          total: Map.get(usage, "total_tokens", 0)
        }

      # Anthropic format
      Map.has_key?(usage, "input_tokens") ->
        input = Map.get(usage, "input_tokens", 0)
        output = Map.get(usage, "output_tokens", 0)
        %{
          input: input,
          output: output,
          total: input + output
        }

      # Gemini format
      Map.has_key?(usage, "promptTokenCount") ->
        %{
          input: Map.get(usage, "promptTokenCount", 0),
          output: Map.get(usage, "candidatesTokenCount", 0),
          total: Map.get(usage, "totalTokenCount", 0)
        }

      true ->
        %{input: 0, output: 0, total: 0}
    end
  end
  def normalize_tokens(_), do: %{input: 0, output: 0, total: 0}

  @doc """
  Extracts and normalizes the generation configuration that was actually applied.
  """
  def extract_applied_config(options, provider_defaults \\ %{}) do
    base_config = Map.merge(provider_defaults, options)

    base_config
    |> Map.take(["max_tokens", "temperature", "top_p", "top_k"])
    |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
  end

  @doc """
  Parses error responses and categorizes them with appropriate error codes.
  """
  def categorize_error(reason) when is_binary(reason) do
    cond do
      String.contains?(reason, "HTTP 401") ->
        %{code: "AUTHENTICATION_ERROR", message: reason, category: :auth}
      String.contains?(reason, "HTTP 429") ->
        %{code: "RATE_LIMIT_EXCEEDED", message: reason, category: :rate_limit}
      String.contains?(reason, "HTTP 400") ->
        %{code: "BAD_REQUEST", message: reason, category: :client_error}
      String.contains?(reason, "HTTP 500") ->
        %{code: "PROVIDER_ERROR", message: reason, category: :server_error}
      String.contains?(reason, "timeout") ->
        %{code: "TIMEOUT", message: reason, category: :timeout}
      true ->
        %{code: "GENERATION_ERROR", message: reason, category: :unknown}
    end
  end

  def categorize_error(:unsupported_model) do
    %{
      code: "MODEL_NOT_FOUND",
      message: "The requested model is not supported",
      category: :validation
    }
  end

  def categorize_error(reason) do
    %{
      code: "UNKNOWN_ERROR",
      message: "Generation failed: #{inspect(reason)}",
      category: :unknown
    }
  end

  defp parse_error_message(error_body) do
    case Jason.decode(error_body) do
      {:ok, %{"error" => %{"message" => message}}} -> message
      {:ok, %{"error" => message}} when is_binary(message) -> message
      _ -> "Unknown error"
    end
  end
end
