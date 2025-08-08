defmodule RaBackend.Workers.IdempotencyCleanupWorker do
  @moduledoc """
  Oban worker for cleaning up expired idempotency keys.
  Should be scheduled to run periodically (e.g., hourly).
  """

  use Oban.Worker, max_attempts: 1

  alias RaBackend.Idempotency

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: _args}) do
    Logger.info("Starting idempotency key cleanup")

    case Idempotency.cleanup_expired_keys() do
      {:ok, count} ->
        Logger.info("Successfully cleaned up #{count} expired idempotency keys")
        :ok

      {:error, reason} ->
        Logger.error("Failed to cleanup expired idempotency keys: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
