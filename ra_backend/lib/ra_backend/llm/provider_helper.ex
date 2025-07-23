defmodule RaBackend.LLM.ProviderHelper do
  @moduledoc "Helper module for LLM providers"
  require Logger

  # Provider-specific minimum tokens for reliable short content generation
  @provider_minimums %{
    openai: 50,      # OpenAI is flexible with low tokens
    anthropic: 75,   # Anthropic needs a bit more
    gemini: 300      # Gemini requires higher minimum for any meaningful content
  }

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

  @doc """
  Ensures token allocation meets provider minimums for reliable generation.
  Critical for short input/output scenarios like prompt polishing.
  """
  def ensure_minimum_tokens(provider, requested_tokens) do
    minimum = Map.get(@provider_minimums, provider, 50)
    max(requested_tokens, minimum)
  end

  @doc """
  Calculates smart token allocation based on input length and provider capabilities.
  """
  def calculate_smart_tokens(prompt, provider, user_max_tokens \\ nil) do
    # Base calculation on prompt length
    prompt_length = String.length(prompt)

    base_tokens = cond do
      prompt_length < 50 -> 75    # Very short prompt
      prompt_length < 150 -> 100  # Short prompt
      prompt_length < 300 -> 150  # Medium prompt
      true -> 200                 # Longer prompt
    end

    # Use user preference if provided, otherwise use calculated
    requested = user_max_tokens || base_tokens

    # Ensure meets provider minimum
    ensure_minimum_tokens(provider, requested)
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
      String.contains?(reason, "Content blocked") ->
        %{code: "CONTENT_FILTERED", message: reason, category: :content_policy}
      String.contains?(reason, "No content generated") ->
        %{code: "GENERATION_INCOMPLETE", message: reason, category: :generation}
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
