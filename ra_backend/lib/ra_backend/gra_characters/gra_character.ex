defmodule RaBackend.GraCharacters.GraCharacter do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "gra_characters" do
    field :name, :string
    field :biography, :string
    field :system_prompt, :string
    field :creation_prompt, :string
    field :llm_model, :string
    field :is_public, :boolean, default: false
    field :soft_delete, :boolean, default: false
    field :metadata, :map, default: %{}

    # Relationships
    belongs_to :user, RaBackend.GraUsers.GraUser
    has_one :unique_handle, RaBackend.GraCharacterHandles.GraCharacterHandle
    many_to_many :labels, RaBackend.GraLabels.GraLabel,
      join_through: "gra_characters_gra_labels",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gra_character, attrs) do
    gra_character
    |> cast(attrs, [:name, :biography, :system_prompt, :creation_prompt, :llm_model, :is_public, :soft_delete, :metadata, :user_id])
    |> validate_required([:name, :is_public, :soft_delete])
    |> put_default_user_id()
    |> validate_metadata()
    |> foreign_key_constraint(:user_id)
  end

  defp put_default_user_id(changeset) do
    case get_field(changeset, :user_id) do
      nil ->
        # Use a known test user ID for prototyping
        put_change(changeset, :user_id, "406a3ece-0136-460d-824a-6ec606e070a4")
      _ -> changeset
    end
  end

  defp validate_metadata(changeset) do
    case get_field(changeset, :metadata) do
      nil -> put_change(changeset, :metadata, %{})
      _ -> changeset
    end
  end
end
