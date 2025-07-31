defmodule Scripts.E2eLlmTest do
  @moduledoc """
  E2E test for LLM endpoints. Call Scripts.E2eLlmTest.run/0 from IEx.
  """

  def run(base_url \\ "http://ra-backend.fly.dev") do
    prompt =
      "Please polish this character creation prompt. Include moment in history. Reply ONLY response. MAX 50 characters: Atheist European philosopher"

    # --- Test Cases ---
    run_tests_for_provider("OpenAI", "gpt-4.1", [50], prompt, base_url)
    run_tests_for_provider("OpenAI", "gpt-4.1-mini", [50], prompt, base_url)
    run_tests_for_provider("Anthropic", "claude-sonnet-4-20250514", [50], prompt, base_url)
    run_tests_for_provider("Gemini", "gemini-2.5-flash-lite", [50], prompt, base_url)
    run_tests_for_provider("Gemini", "gemini-2.5-flash", [5000], prompt, base_url)
  end

  defp run_tests_for_provider(provider_name, model, token_counts, prompt, base_url) do
    Enum.each(token_counts, fn max_tokens ->
      body = %{
        "model" => model,
        "prompt" => prompt,
        "options" => %{"max_tokens" => max_tokens, "temperature" => 0.7}
      }

      IO.puts("\n=== Testing #{provider_name} (#{model}) with max_tokens=#{max_tokens} ===")

      {time, result} =
        :timer.tc(fn ->
          HTTPoison.post(
            base_url <> "/api/llm/generate",
            Jason.encode!(body),
            [{"Content-Type", "application/json"}],
            recv_timeout: 30_000
          )
        end)

      duration_ms = System.convert_time_unit(time, :microsecond, :millisecond)
      IO.puts("Request took: #{duration_ms} ms")

      case result do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          resp = Jason.decode!(body)
          IO.puts("Success: #{inspect(resp["success"])}")
          IO.puts("Content: #{resp["data"]["content"]}")
          IO.puts("Tokens Used: #{inspect(resp["metadata"]["tokens"])}")
        {:ok, %HTTPoison.Response{status_code: code, body: body}} ->
          IO.puts("Non-200 response: #{code}")
          IO.puts(body)
        {:error, err} ->
          IO.puts("Request failed: #{inspect(err)}")
      end
    end)
  end
end
