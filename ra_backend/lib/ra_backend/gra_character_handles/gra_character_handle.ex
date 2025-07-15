defmodule RaBackend.GraCharacterHandles.GraCharacterHandle do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "gra_character_handles" do
    field :handle_name, :string
    field :is_primary, :boolean, default: false
    field :is_active, :boolean, default: false

    # Relationships
    belongs_to :gra_character, RaBackend.GraCharacters.GraCharacter

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gra_character_handle, attrs) do
    gra_character_handle
    |> cast(attrs, [:handle_name, :is_primary, :is_active, :gra_character_id])
    |> validate_required([:handle_name, :is_primary, :is_active, :gra_character_id])
    |> validate_handle_name_format()
    |> foreign_key_constraint(:gra_character_id)
  end

  defp validate_handle_name_format(changeset) do
    case get_field(changeset, :handle_name) do
      nil -> changeset
      handle_name ->
        if String.match?(handle_name, ~r/^[a-zA-Z0-9_]{3,20}$/) do
          changeset
        else
          add_error(changeset, :handle_name, "must be 3-20 characters, alphanumeric and underscores only")
        end
    end
  end
end
