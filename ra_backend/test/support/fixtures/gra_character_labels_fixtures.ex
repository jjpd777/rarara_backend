defmodule RaBackend.GraCharacterLabelsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RaBackend.GraCharacterLabels` context.
  """

  @doc """
  Generate a gra_character_label.
  """
  def gra_character_label_fixture(attrs \\ %{}) do
    {:ok, gra_character_label} =
      attrs
      |> Enum.into(%{

      })
      |> RaBackend.GraCharacterLabels.create_gra_character_label()

    gra_character_label
  end
end
