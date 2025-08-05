defmodule RaBackend.ImageGen.ImageService do
  @moduledoc """
  Service layer for image generation requests.
  Handles validation, preprocessing, and provider routing.
  """

  alias RaBackend.ImageGen.ProviderRouter

  def generate_image(params) do
    # TODO: Add validation and preprocessing as needed
    ProviderRouter.route_request(params)
  end
end
