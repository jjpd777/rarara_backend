defmodule RaBackend.GraLabelsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `RaBackend.GraLabels` context.
  """

  @doc """
  Generate a gra_label.
  """
  def gra_label_fixture(attrs \\ %{}) do
    {:ok, gra_label} =
      attrs
      |> Enum.into(%{
        category: "some category",
        color: "some color",
        description: "some description",
        icon: "some icon",
        is_active: true,
        is_public: true,
        metadata: %{},
        name: "some name",
        priority: 42,
        soft_delete: true,
        subcategory: "some subcategory"
      })
      |> RaBackend.GraLabels.create_gra_label()

    gra_label
  end
end
