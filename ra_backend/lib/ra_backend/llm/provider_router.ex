defmodule RaBackend.LLM.ProviderRouter do
  @moduledoc "Routes requests to appropriate LLM provider based on model name"

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
end
