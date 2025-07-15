defmodule RaBackend.Repo.Migrations.CreateGraCharacterHandles do
  use Ecto.Migration

  def change do
    create table(:gra_character_handles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :handle_name, :string, null: false
      add :is_primary, :boolean, default: false, null: false
      add :is_active, :boolean, default: false, null: false
      add :gra_character_id, references(:gra_characters, on_delete: :restrict, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:gra_character_handles, [:gra_character_id])
    create unique_index(:gra_character_handles, [:handle_name])
  end
end
