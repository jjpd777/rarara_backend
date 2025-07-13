defmodule RaBackend.GraUsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RaBackend.GraUsers` context.
  """

  @doc """
  Generate a gra_user.
  """
  def gra_user_fixture(attrs \\ %{}) do
    {:ok, gra_user} =
      attrs
      |> Enum.into(%{
        apple_id: "some apple_id",
        avatar_url: "some avatar_url",
        email: "some email",
        first_name: "some first_name",
        is_active: true,
        is_verified: true,
        last_sign_in_at: ~U[2025-07-12 21:49:00Z],
        metadata: %{},
        sign_in_count: 42
      })
      |> RaBackend.GraUsers.create_gra_user()

    gra_user
  end
end
