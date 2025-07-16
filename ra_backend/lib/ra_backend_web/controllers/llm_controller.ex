defmodule RaBackendWeb.LLMController do
  use RaBackendWeb, :controller

  def generate(conn, %{"prompt" => prompt, "model" => model} = params) do
    request = %{
      prompt: prompt,
      model: model,
      options: Map.get(params, "options", %{})
    }

    case RaBackend.LLM.ProviderRouter.route_request(request) do
      {:ok, %{"content" => content}} ->  # If provider returns a map with string keys
        json(conn, %{content: content})
      {:ok, %{content: content}} ->       # If provider returns a map with atom keys
        json(conn, %{content: content})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end
end
