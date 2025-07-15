defmodule RaBackend.GraCharacterLabels.GraCharacterLabel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "gra_characters_gra_labels" do

    field :gra_character_id, :id
    field :gra_label_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gra_character_label, attrs) do
    gra_character_label
    |> cast(attrs, [])
    |> validate_required([])
  end
end
