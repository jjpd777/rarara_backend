defmodule RaBackendWeb.LLMController do
  use RaBackendWeb, :controller
  require Logger
  alias RaBackend.LLM.LLMService.Request
  alias RaBackend.LLM.ProviderRouter

  def generate(conn, %{"prompt" => prompt, "model" => model} = params) do
    request = %Request{
      prompt: prompt,
      model: model,
      options: Map.get(params, "options", %{})
    }

    log_request(request)

    case ProviderRouter.route_request_with_retry(request) do
      {:ok, response} ->
        log_success(response)
        json(conn, %{content: response.content})
      {:error, reason} ->
        log_error(request, reason)
        conn
        |> put_status(:bad_request)
        |> json(%{error: format_error(reason)})
    end
  end

  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(:unsupported_model), do: "The requested model is not supported."
  defp format_error(reason), do: "Generation failed: #{inspect(reason)}"

  defp log_request(%Request{model: model, prompt: prompt}) do
    Logger.info("LLM Request: model=#{model}, prompt_length=#{String.length(prompt)}")
  end

  defp log_success(response) do
    Logger.info("LLM Success: model=#{response.model}, provider=#{response.provider}")
  end

  defp log_error(%Request{model: model}, reason) do
    Logger.error("LLM Error: model=#{model}, reason=#{inspect(reason)}")
  end
end
