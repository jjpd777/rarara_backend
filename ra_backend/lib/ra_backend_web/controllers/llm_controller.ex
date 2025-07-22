defmodule RaBackendWeb.LLMController do
  use RaBackendWeb, :controller
  require Logger
  alias RaBackend.LLM.LLMService.Request
  alias RaBackend.LLM.ProviderRouter
  alias RaBackend.LLM.ModelRegistry
  alias RaBackend.LLM.ProviderHelper

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
        json(conn, build_success_response(response))

      {:error, error_details} ->
        log_error(request, error_details)

        conn
        |> put_status(get_error_status(error_details))
        |> json(build_error_response(error_details, request))
    end
  end

  def list_models(conn, _params) do
    models = ModelRegistry.all_for_api()

    json(conn, %{
      success: true,
      data: %{
        models: models
      },
      metadata: %{
        totalCount: length(models),
        timestamp: DateTime.utc_now()
      }
    })
  end

  # Private helper functions for building responses

  defp build_success_response(response) do
    %{
      success: true,
      data: %{
        content: response.content,
        generationId: response.generation_id
      },
      metadata: %{
        model: response.model,
        provider: to_string(response.provider),
        tokens: build_tokens_metadata(response),
        config: build_config_metadata(response),
        timing: build_timing_metadata(response),
        request: build_request_metadata(response)
      }
    }
  end

  defp build_error_response(error_details, request) do
    error_info = parse_error_details(error_details)

    %{
      success: false,
      error: %{
        code: error_info.code,
        message: error_info.message,
        details: build_error_details(error_details, request)
      },
      metadata: %{
        requestId: get_generation_id(error_details),
        timestamp: DateTime.utc_now(),
        attemptedModel: request.model
      }
    }
  end

  defp build_tokens_metadata(response) do
    normalized_tokens = ProviderHelper.normalize_tokens(response.usage || %{})
    max_requested = get_in(response.applied_config, [:max_tokens]) || 0

    %{
      input: normalized_tokens.input,
      output: normalized_tokens.output,
      total: normalized_tokens.total,
      maxRequested: max_requested
    }
  end

  defp build_config_metadata(response) do
    config = response.applied_config || %{}

    %{
      temperature: Map.get(config, :temperature),
      finishReason: response.finish_reason
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp build_timing_metadata(response) do
    timing = response.timing_info || %{}

    %{
      responseMs: Map.get(timing, :total_ms)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp build_request_metadata(response) do
    metadata = response.request_metadata || %{}

    %{
      attemptNumber: Map.get(metadata, :attempt_number),
      retryCount: Map.get(metadata, :retry_count),
      timestamp: Map.get(metadata, :timestamp)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  defp build_error_details(error_details, request) when is_map(error_details) do
    case Map.get(error_details, :reason) do
      :unsupported_model ->
        %{
          requestedModel: request.model,
          availableModels: Enum.map(ModelRegistry.all_for_api(), & &1.model)
        }
      _ ->
        %{}
    end
  end
  defp build_error_details(_, _), do: %{}

  defp parse_error_details(error_details) when is_map(error_details) do
    case Map.get(error_details, :reason) do
      reason when not is_nil(reason) ->
        ProviderHelper.categorize_error(reason)
      _ ->
        ProviderHelper.categorize_error(error_details)
    end
  end
  defp parse_error_details(error_details) do
    ProviderHelper.categorize_error(error_details)
  end

  defp get_error_status(error_details) when is_map(error_details) do
    case Map.get(error_details, :reason) do
      :unsupported_model -> :bad_request
      reason when is_binary(reason) -> get_status_from_reason(reason)
      _ -> :internal_server_error
    end
  end
  defp get_error_status(reason) when is_atom(reason) do
    case reason do
      :unsupported_model -> :bad_request
      _ -> :internal_server_error
    end
  end
  defp get_error_status(_), do: :internal_server_error

  defp get_status_from_reason(reason) do
    cond do
      String.contains?(reason, "HTTP 401") -> :unauthorized
      String.contains?(reason, "HTTP 429") -> :too_many_requests
      String.contains?(reason, "HTTP 400") -> :bad_request
      String.contains?(reason, "HTTP 500") -> :bad_gateway
      String.contains?(reason, "timeout") -> :request_timeout
      true -> :bad_request
    end
  end

  defp get_generation_id(error_details) when is_map(error_details) do
    Map.get(error_details, :generation_id)
  end
  defp get_generation_id(_), do: nil

  # Updated logging functions
  defp log_request(%Request{model: model, prompt: prompt}) do
    Logger.info("LLM Request: model=#{model}, prompt_length=#{String.length(prompt)}")
  end

  defp log_success(response) do
    Logger.info("LLM Success: model=#{response.model}, provider=#{response.provider}, id=#{response.generation_id}")
  end

  defp log_error(%Request{model: model}, error_details) do
    generation_id = get_generation_id(error_details)
    Logger.error("LLM Error: model=#{model}, error=#{inspect(error_details)}, id=#{generation_id}")
  end
end
