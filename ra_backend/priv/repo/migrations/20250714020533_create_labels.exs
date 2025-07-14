defmodule RaBackend.Repo.Migrations.CreateLabels do
  use Ecto.Migration

  def change do
    create table(:labels, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :text
      add :category, :string
      add :subcategory, :string
      add :color, :string
      add :icon, :string
      add :priority, :integer
      add :is_active, :boolean, default: false, null: false
      add :is_public, :boolean, default: false, null: false
      add :soft_delete, :boolean, default: false, null: false
      add :metadata, :map
      add :created_by_id, references(:users, on_delete: :restrict, type: :binary_id), null: true
      add :updated_by_id, references(:users, on_delete: :restrict, type: :binary_id), null: true

      timestamps(type: :utc_datetime)
    end

    create index(:labels, [:created_by_id])
    create index(:labels, [:updated_by_id])
  end
end
