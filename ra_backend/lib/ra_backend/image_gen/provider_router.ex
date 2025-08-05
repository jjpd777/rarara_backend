defmodule RaBackend.ImageGen.ProviderRouter do
  @moduledoc """
  Routes image generation requests to the appropriate provider based on the model.
  """

  alias RaBackend.ModelRegistry

  def route_request(%{model: model} = params) do
    with {:ok, provider} <- ModelRegistry.find_provider_by_model(model) do
      provider.generate_image(params)
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
