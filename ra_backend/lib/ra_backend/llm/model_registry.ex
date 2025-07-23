defmodule RaBackend.LLM.ModelRegistry do
  @moduledoc """
  A central registry for all supported LLM models.
  Acts as a single source of truth for model definitions and capabilities.
  """

  alias RaBackend.LLM.Providers

  @models [
    %{
      house: "OpenAI",
      model: "gpt-4.1",
      display_name: "OpenAI - GPT-4.1",
      provider: Providers.OpenAI,
      model_type: :text_gen
    },
    %{
      house: "Anthropic",
      model: "claude-sonnet-4-20250514",
      display_name: "Anthropic - Claude Sonnet 4",
      provider: Providers.Anthropic,
      model_type: :text_gen
    },
    %{
      house: "Google",
      model: "gemini-2.5-pro",
      display_name: "Google - Gemini 2.5 Flash",
      provider: Providers.Gemini,
      model_type: :text_gen
    },
    %{
      house: "Google",
      model: "gemini-2.5",
      display_name: "Google - Gemini 2.5",
      provider: Providers.Gemini,
      model_type: :text_gen
    },
    %{
      house: "Google",
      model: "gemini-2.5-pro",
      display_name: "Google - Gemini 2.5 Pro",
      provider: Providers.Gemini,
      model_type: :text_gen
    }
  ]

  @doc """
  Returns a list of all models suitable for public API consumption.
  The provider module is dropped to avoid leaking internal details.
  """
  def all_for_api do
    Enum.map(@models, &Map.drop(&1, [:provider]))
  end

  @doc "Finds a model's provider by its unique model string."
  def find_provider_by_model(model_string) do
    case Enum.find(@models, &(&1.model == model_string)) do
      nil -> {:error, :unsupported_model}
      model -> {:ok, model.provider}
    end
  end
end
