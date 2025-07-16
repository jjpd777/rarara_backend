defmodule RaBackendWeb.LLMController do
  use RaBackendWeb, :controller
  require Logger

  def generate(conn, %{"prompt" => prompt, "model" => model} = params) do
    request = %{
      prompt: prompt,
      model: model,
      options: Map.get(params, "options", %{})
    }

    Logger.info("LLM Request: model=#{model}, prompt_length=#{String.length(prompt)}")

    case RaBackend.LLM.ProviderRouter.route_request_with_retry(request) do
      {:ok, %{"content" => content}} ->
        Logger.info("LLM Success: model=#{model}")
        json(conn, %{content: content})
      {:ok, %{content: content}} ->
        Logger.info("LLM Success: model=#{model}")
        json(conn, %{content: content})
      {:error, reason} ->
        Logger.error("LLM Error: model=#{model}, reason=#{inspect(reason)}")
        conn
        |> put_status(:bad_request)
        |> json(%{error: format_error(reason)})
    end
  end

  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: "Generation failed: #{inspect(reason)}"
end
