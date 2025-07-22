defmodule RaBackend.LLM.LLMService do
  @moduledoc "Unified LLM service interface"

  defmodule Request do
    @moduledoc "Struct for an LLM request."
    @enforce_keys [:prompt, :model]
    defstruct [:prompt, :model, :generation_id, options: %{}, start_time: nil]
  end

  defmodule Response do
    @moduledoc "Struct for a unified LLM response."
    @enforce_keys [:content, :model, :provider, :finish_reason]
    defstruct [
      :content, :model, :provider, :usage, :finish_reason, :raw_response,
      :generation_id, :applied_config, :timing_info, :request_metadata
    ]
  end

  @type llm_request :: %Request{}
  @type llm_response :: %Response{}

  @callback generate(llm_request()) :: {:ok, llm_response()} | {:error, term()}
end
