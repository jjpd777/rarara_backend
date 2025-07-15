defmodule RaBackend.Repo.Migrations.CreateGraCharacters do
  use Ecto.Migration

  def change do
    create table(:gra_characters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :biography, :text
      add :system_prompt, :text
      add :creation_prompt, :text
      add :llm_model, :string
      add :is_public, :boolean, default: false, null: false
      add :soft_delete, :boolean, default: false, null: false
      add :user_id, references(:users, on_delete: :restrict, type: :binary_id)
      add :metadata, :map, default: %{}, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:gra_characters, [:user_id])
    create index(:gra_characters, [:is_public])
    create index(:gra_characters, [:soft_delete])
  end
end
