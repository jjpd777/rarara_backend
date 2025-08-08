defmodule RaBackend.Repo.Migrations.CreateIdempotencyKeys do
  use Ecto.Migration

  def change do
    create table(:idempotency_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :binary_id, null: false
      add :idempotency_key, :string, null: false
      add :task_id, :binary_id, null: true
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:idempotency_keys, [:user_id, :idempotency_key])
    create index(:idempotency_keys, [:expires_at])
    create index(:idempotency_keys, [:task_id])
  end
end
