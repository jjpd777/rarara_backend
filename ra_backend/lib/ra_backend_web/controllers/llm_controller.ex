defmodule RaBackendWeb.LLMController do
  use RaBackendWeb, :controller

  def generate(conn, %{"prompt" => prompt, "model" => model} = params) do
    request = %{
      prompt: prompt,
      model: model,
      options: Map.get(params, "options", %{})
    }

    case RaBackend.LLM.ProviderRouter.route_request(request) do
      {:ok, response} ->
        json(conn, %{success: true, data: response})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{success: false, error: reason})
    end
  end
end
