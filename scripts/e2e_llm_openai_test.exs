defmodule Scripts.E2eLlmOpenaiTest do
  @moduledoc """
  E2E test for OpenAI and Anthropic LLM endpoints. Call Scripts.E2eLlmOpenaiTest.run/0 from IEx.
  """

  def run(base_url \\ "http://localhost:4000") do
    prompt = "Please polish this character creation prompt. Include moment in history. Reply ONLY response. MAX 50 characters: Medieval monk"
    token_counts = [50, 40, 30]

    # Test OpenAI
    model = "gpt-4.1"
    Enum.each(token_counts, fn max_tokens ->
      body = %{
        "model" => model,
        "prompt" => prompt,
        "options" => %{"max_tokens" => max_tokens, "temperature" => 0.7}
      }

      IO.puts("\n=== Testing OpenAI (#{model}) with max_tokens=#{max_tokens} ===")

      case HTTPoison.post(
             base_url <> "/api/llm/generate",
             Jason.encode!(body),
             [{"Content-Type", "application/json"}],
             recv_timeout: 30_000
           ) do
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

    # Test Anthropic
    model = "claude-sonnet-4-20250514"
    Enum.each(token_counts, fn max_tokens ->
      body = %{
        "model" => model,
        "prompt" => prompt,
        "options" => %{"max_tokens" => max_tokens, "temperature" => 0.7}
      }

      IO.puts("\n=== Testing Anthropic (#{model}) with max_tokens=#{max_tokens} ===")

      case HTTPoison.post(
             base_url <> "/api/llm/generate",
             Jason.encode!(body),
             [{"Content-Type", "application/json"}],
             recv_timeout: 30_000
           ) do
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
