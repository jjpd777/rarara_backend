defmodule RaBackend.GraCharacterHandlesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RaBackend.GraCharacterHandles` context.
  """

  @doc """
  Generate a gra_character_handle.
  """
  def gra_character_handle_fixture(attrs \\ %{}) do
    {:ok, gra_character_handle} =
      attrs
      |> Enum.into(%{
        handle_name: "some handle_name",
        is_active: true,
        is_primary: true
      })
      |> RaBackend.GraCharacterHandles.create_gra_character_handle()

    gra_character_handle
  end
end
