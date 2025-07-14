defmodule RaBackend.GraLabels.GraLabel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "labels" do
    field :name, :string
    field :priority, :integer
    field :description, :string
    field :metadata, :map
    field :category, :string
    field :color, :string
    field :subcategory, :string
    field :icon, :string
    field :is_active, :boolean, default: true
    field :is_public, :boolean, default: false
    field :soft_delete, :boolean, default: false

    # Proper associations
    belongs_to :created_by_user, RaBackend.GraUsers.GraUser, foreign_key: :created_by_id, type: :binary_id
    belongs_to :updated_by_user, RaBackend.GraUsers.GraUser, foreign_key: :updated_by_id, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gra_label, attrs) do
    gra_label
    |> cast(attrs, [:name, :description, :category, :subcategory, :color, :icon, :priority, :is_active, :is_public, :soft_delete, :metadata, :created_by_id, :updated_by_id])
    |> validate_required([:name, :is_active, :is_public, :soft_delete])
    |> validate_metadata()
  end

  defp validate_metadata(changeset) do
    case get_field(changeset, :metadata) do
      nil -> put_change(changeset, :metadata, %{})
      _ -> changeset
    end
  end
end
