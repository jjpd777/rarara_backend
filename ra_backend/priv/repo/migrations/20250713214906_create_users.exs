defmodule RaBackend.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :apple_id, :string, null: true  # Can be null for non-Apple users
      add :email, :string, null: true
      add :first_name, :string, null: true
      add :last_name, :string, null: true
      add :avatar_url, :string, null: true
      add :is_active, :boolean, default: true, null: false
      add :is_verified, :boolean, default: false, null: false
      add :last_sign_in_at, :utc_datetime, null: true
      add :sign_in_count, :integer, default: 0, null: false
      add :metadata, :map, default: %{}, null: false

      timestamps(type: :utc_datetime)
    end

    # Add constraints and indexes
    create unique_index(:users, [:apple_id], where: "apple_id IS NOT NULL")
    create unique_index(:users, [:email], where: "email IS NOT NULL")
    create index(:users, [:is_active])
  end
end
