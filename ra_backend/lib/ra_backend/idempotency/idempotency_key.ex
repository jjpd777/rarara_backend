defmodule RaBackend.Idempotency.IdempotencyKey do
  @moduledoc """
  Schema for idempotency keys to prevent duplicate video generation requests.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "idempotency_keys" do
    field :user_id, :binary_id
    field :idempotency_key, :string
    field :task_id, :binary_id
    field :expires_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(idempotency_key, attrs) do
    idempotency_key
    |> cast(attrs, [:user_id, :idempotency_key, :task_id, :expires_at])
    |> validate_required([:user_id, :idempotency_key, :expires_at])
    |> unique_constraint([:user_id, :idempotency_key])
    |> validate_length(:idempotency_key, min: 1, max: 255)
  end

  @doc """
  Creates changeset for initial key storage (without task_id).
  """
  def initial_changeset(idempotency_key, attrs) do
    idempotency_key
    |> cast(attrs, [:user_id, :idempotency_key, :expires_at])
    |> validate_required([:user_id, :idempotency_key, :expires_at])
    |> unique_constraint([:user_id, :idempotency_key])
    |> validate_length(:idempotency_key, min: 1, max: 255)
  end

  @doc """
  Creates changeset for linking task_id to existing key.
  """
  def link_task_changeset(idempotency_key, task_id) do
    idempotency_key
    |> cast(%{task_id: task_id}, [:task_id])
    |> validate_required([:task_id])
  end
end
