defmodule RaBackend.GraCharacterLabels do
  @moduledoc """
  The GraCharacterLabels context.
  """

  import Ecto.Query, warn: false
  alias RaBackend.Repo

  alias RaBackend.GraCharacterLabels.GraCharacterLabel

  @doc """
  Returns the list of gra_characters_gra_labels.

  ## Examples

      iex> list_gra_characters_gra_labels()
      [%GraCharacterLabel{}, ...]

  """
  def list_gra_characters_gra_labels do
    Repo.all(GraCharacterLabel)
  end

  @doc """
  Gets a single gra_character_label.

  Raises `Ecto.NoResultsError` if the Gra character label does not exist.

  ## Examples

      iex> get_gra_character_label!(123)
      %GraCharacterLabel{}

      iex> get_gra_character_label!(456)
      ** (Ecto.NoResultsError)

  """
  def get_gra_character_label!(id), do: Repo.get!(GraCharacterLabel, id)

  @doc """
  Creates a gra_character_label.

  ## Examples

      iex> create_gra_character_label(%{field: value})
      {:ok, %GraCharacterLabel{}}

      iex> create_gra_character_label(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_gra_character_label(attrs \\ %{}) do
    %GraCharacterLabel{}
    |> GraCharacterLabel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a gra_character_label.

  ## Examples

      iex> update_gra_character_label(gra_character_label, %{field: new_value})
      {:ok, %GraCharacterLabel{}}

      iex> update_gra_character_label(gra_character_label, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_gra_character_label(%GraCharacterLabel{} = gra_character_label, attrs) do
    gra_character_label
    |> GraCharacterLabel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a gra_character_label.

  ## Examples

      iex> delete_gra_character_label(gra_character_label)
      {:ok, %GraCharacterLabel{}}

      iex> delete_gra_character_label(gra_character_label)
      {:error, %Ecto.Changeset{}}

  """
  def delete_gra_character_label(%GraCharacterLabel{} = gra_character_label) do
    Repo.delete(gra_character_label)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking gra_character_label changes.

  ## Examples

      iex> change_gra_character_label(gra_character_label)
      %Ecto.Changeset{data: %GraCharacterLabel{}}

  """
  def change_gra_character_label(%GraCharacterLabel{} = gra_character_label, attrs \\ %{}) do
    GraCharacterLabel.changeset(gra_character_label, attrs)
  end
end
