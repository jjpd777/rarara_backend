defmodule RaBackend.LLM.LLMService do
  @moduledoc "Unified LLM service interface"

  @type llm_request :: %{
    prompt: String.t(),
    model: String.t(),
    options: map() | nil
  }

  @type llm_response :: %{
    content: String.t(),
    model: String.t(),
    provider: atom(),
    usage: map(),
    finish_reason: String.t(),
    raw_response: map()
  }

  @callback generate(llm_request()) :: {:ok, llm_response()} | {:error, term()}
end
