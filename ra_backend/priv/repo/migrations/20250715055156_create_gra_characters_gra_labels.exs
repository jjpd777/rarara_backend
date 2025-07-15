defmodule RaBackend.Repo.Migrations.CreateGraCharactersGraLabels do
  use Ecto.Migration

  def change do
    create table(:gra_characters_gra_labels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :gra_character_id, references(:gra_characters, on_delete: :delete_all, type: :binary_id), null: false
      add :gra_label_id, references(:labels, on_delete: :delete_all, type: :binary_id), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:gra_characters_gra_labels, [:gra_character_id])
    create index(:gra_characters_gra_labels, [:gra_label_id])
    create unique_index(:gra_characters_gra_labels, [:gra_character_id, :gra_label_id])
  end
end
