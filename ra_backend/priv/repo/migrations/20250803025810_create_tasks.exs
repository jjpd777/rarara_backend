defmodule RaBackend.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, :binary_id, null: false
      add :status, :string, null: false, default: "queued"
      add :progress, :float, null: false, default: 0.0
      add :input_data, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:user_id])
    create index(:tasks, [:status])
    create index(:tasks, [:inserted_at])
  end
end
