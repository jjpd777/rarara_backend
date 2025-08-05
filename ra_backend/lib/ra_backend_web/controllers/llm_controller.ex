defmodule RaBackendWeb.LLMController do
  use RaBackendWeb, :controller

  alias RaBackend.ModelRegistry
  alias RaBackend.LLM.LLMService.Request
  alias RaBackend.LLM.ProviderRouter

  require Logger

  def models(conn, _params) do
    models = ModelRegistry.all_by_type(:text_gen)
    json(conn, %{models: models})
  end

  def generate(conn, params) do
    with {:ok, request} <- build_request(params),
         {:ok, response} <- ProviderRouter.route_request_with_retry(request) do

      json(conn, %{
        success: true,
        data: %{
          content: response.content,
          model: response.model,
          provider: response.provider,
          generation_id: response.generation_id
        }
      })
    else
      {:error, :validation_error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: %{
            code: "validation_error",
            message: message
          }
        })

      {:error, reason} ->
        Logger.error("LLM generation failed: #{inspect(reason)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{
          success: false,
          error: %{
            code: "generation_failed",
            message: "Failed to generate response"
          }
        })
    end
  end

  defp build_request(params) do
    prompt = Map.get(params, "prompt")
    model = Map.get(params, "model")
    options = Map.get(params, "options", %{})

    cond do
      is_nil(prompt) or prompt == "" ->
        {:error, :validation_error, "Prompt is required"}

      is_nil(model) or model == "" ->
        {:error, :validation_error, "Model is required"}

      true ->
        {:ok, %Request{
          prompt: prompt,
          model: model,
          options: options
        }}
    end
  end
end
