defmodule RaBackend.Idempotency do
  @moduledoc """
  Context module for handling idempotency keys to prevent duplicate video generation requests.
  """

  import Ecto.Query, warn: false
  alias RaBackend.Repo
  alias RaBackend.Idempotency.IdempotencyKey
  alias RaBackend.Tasks.Task

  require Logger

  @ttl_hours 24

  @doc """
  Finds an existing task by user_id and idempotency_key.
  Returns the task if found and not expired, otherwise :not_found.
  """
  def find_task_by_key(user_id, idempotency_key) when is_binary(idempotency_key) do
    now = DateTime.utc_now()

    query =
      from ik in IdempotencyKey,
        join: t in Task,
        on: ik.task_id == t.id,
        where: ik.user_id == ^user_id and
               ik.idempotency_key == ^idempotency_key and
               ik.expires_at > ^now,
        select: t

    case Repo.one(query) do
      nil -> {:error, :not_found}
      task -> {:ok, task}
    end
  end

  def find_task_by_key(_user_id, nil), do: {:error, :not_found}
  def find_task_by_key(_user_id, ""), do: {:error, :not_found}

  @doc """
  Stores an idempotency key immediately to prevent race conditions.
  This creates a "reservation" before the actual task is created.
  """
  def store_key(user_id, idempotency_key) when is_binary(idempotency_key) do
    expires_at = DateTime.utc_now() |> DateTime.add(@ttl_hours, :hour)

    attrs = %{
      user_id: user_id,
      idempotency_key: idempotency_key,
      expires_at: expires_at
    }

    case %IdempotencyKey{}
         |> IdempotencyKey.initial_changeset(attrs)
         |> Repo.insert() do
      {:ok, idempotency_record} ->
        Logger.debug("Stored idempotency key: #{idempotency_key} for user: #{user_id}")
        {:ok, idempotency_record}

      {:error, %Ecto.Changeset{errors: errors} = changeset} ->
        # Check if it's a unique constraint violation
        case Enum.find(errors, fn {field, {_msg, opts}} ->
          field in [:user_id, :idempotency_key] and
          Keyword.get(opts, :constraint) == :unique
        end) do
          nil ->
            Logger.error("Failed to store idempotency key: #{inspect(errors)}")
            {:error, changeset}

          _ ->
            # Duplicate key constraint - another request beat us to it
            Logger.info("Idempotency key already exists: #{idempotency_key} for user: #{user_id}")
            {:error, :already_exists}
        end
    end
  end

  def store_key(_user_id, nil), do: {:error, :invalid_key}
  def store_key(_user_id, ""), do: {:error, :invalid_key}

  @doc """
  Links a task_id to an existing idempotency key.
  This completes the idempotency record after successful task creation.
  """
  def link_task_to_key(user_id, idempotency_key, task_id) do
    case get_key_record(user_id, idempotency_key) do
      {:ok, idempotency_record} ->
        idempotency_record
        |> IdempotencyKey.link_task_changeset(task_id)
        |> Repo.update()
        |> case do
          {:ok, _updated_record} ->
            Logger.debug("Linked task #{task_id} to idempotency key: #{idempotency_key}")
            :ok

          {:error, changeset} ->
            Logger.error("Failed to link task to idempotency key: #{inspect(changeset.errors)}")
            {:error, changeset}
        end

      {:error, reason} ->
        Logger.error("Could not find idempotency key to link: #{idempotency_key}")
        {:error, reason}
    end
  end

  @doc """
  Deletes an idempotency key (used for cleanup on task creation failure).
  """
  def delete_key(user_id, idempotency_key) do
    case get_key_record(user_id, idempotency_key) do
      {:ok, idempotency_record} ->
        case Repo.delete(idempotency_record) do
          {:ok, _deleted_record} ->
            Logger.debug("Deleted idempotency key: #{idempotency_key}")
            :ok

          {:error, changeset} ->
            Logger.error("Failed to delete idempotency key: #{inspect(changeset.errors)}")
            {:error, changeset}
        end

      {:error, reason} ->
        Logger.warn("Could not find idempotency key to delete: #{idempotency_key}")
        {:error, reason}
    end
  end

  @doc """
  Cleans up expired idempotency keys.
  Should be called periodically (e.g., via Oban cron job).
  """
  def cleanup_expired_keys do
    now = DateTime.utc_now()

    {deleted_count, _} =
      from(ik in IdempotencyKey, where: ik.expires_at <= ^now)
      |> Repo.delete_all()

    Logger.info("Cleaned up #{deleted_count} expired idempotency keys")
    {:ok, deleted_count}
  end

  # Private helper to get idempotency key record
  defp get_key_record(user_id, idempotency_key) do
    query =
      from ik in IdempotencyKey,
        where: ik.user_id == ^user_id and ik.idempotency_key == ^idempotency_key

    case Repo.one(query) do
      nil -> {:error, :not_found}
      record -> {:ok, record}
    end
  end
end
