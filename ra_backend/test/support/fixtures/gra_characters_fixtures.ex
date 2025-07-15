defmodule RaBackend.GraCharactersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RaBackend.GraCharacters` context.
  """

  @doc """
  Generate a gra_character.
  """
  def gra_character_fixture(attrs \\ %{}) do
    {:ok, gra_character} =
      attrs
      |> Enum.into(%{
        biography: "some biography",
        creation_prompt: "some creation_prompt",
        is_public: true,
        llm_model: "some llm_model",
        name: "some name",
        soft_delete: true,
        system_prompt: "some system_prompt"
      })
      |> RaBackend.GraCharacters.create_gra_character()

    gra_character
  end
end
