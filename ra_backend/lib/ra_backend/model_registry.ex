defmodule RaBackend.ModelRegistry do
  @moduledoc """
  Central registry for all supported models (text, image, etc.).
  """

  @models [
    # Text models
    %{
      house: "OpenAI",
      model: "gpt-4.1",
      display_name: "OpenAI - GPT-4.1",
      provider: RaBackend.LLM.Providers.OpenAI,
      model_type: :text_gen
    },
    %{
      house: "Anthropic",
      model: "claude-sonnet-4-20250514",
      display_name: "Anthropic - Claude Sonnet 4",
      provider: RaBackend.LLM.Providers.Anthropic,
      model_type: :text_gen
    },
    %{
      house: "Google",
      model: "gemini-2.5-flash-lite",
      display_name: "Google - Gemini 2.5 Flash Lite",
      provider: RaBackend.LLM.Providers.Gemini,
      model_type: :text_gen
    },
    # Image models
    %{
      house: "Replicate",
      model: "google/imagen-4-fast",
      display_name: "Replicate - Imagen 4 Fast",
      provider: RaBackend.ImageGen.Providers.Replicate,
      model_type: :image_gen
    },
    %{
      house: "Replicate",
      model: "bytedance/seedream-3",
      display_name: "Replicate - Seedream 3",
      provider: RaBackend.ImageGen.Providers.Replicate,
      model_type: :image_gen
    },
    # Video models
    %{
      house: "Replicate",
      model: "bytedance/seedance-1-pro",
      display_name: "Replicate - Seedance 1 Pro",
      provider: RaBackend.ImageGen.Providers.Replicate,
      model_type: :video_gen
    }
    # Add more models as needed
  ]

  def all_for_api, do: Enum.map(@models, &Map.drop(&1, [:provider]))
  def all_by_type(type), do: Enum.filter(@models, &(&1.model_type == type))
  def find_provider_by_model(model_string) do
    case Enum.find(@models, &(&1.model == model_string)) do
      nil -> {:error, :unsupported_model}
      model -> {:ok, model.provider}
    end
  end
end
