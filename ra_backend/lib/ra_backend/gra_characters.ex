defmodule RaBackend.GraCharacters do
  @moduledoc """
  The GraCharacters context.
  """

  import Ecto.Query, warn: false
  alias RaBackend.Repo

  alias RaBackend.GraCharacters.GraCharacter

  @doc """
  Returns the list of gra_characters.

  ## Examples

      iex> list_gra_characters()
      [%GraCharacter{}, ...]

  """
  def list_gra_characters do
    Repo.all(GraCharacter)
  end

  @doc """
  Gets a single gra_character.

  Raises `Ecto.NoResultsError` if the Gra character does not exist.

  ## Examples

      iex> get_gra_character!(123)
      %GraCharacter{}

      iex> get_gra_character!(456)
      ** (Ecto.NoResultsError)

  """
  def get_gra_character!(id), do: Repo.get!(GraCharacter, id)

  @doc """
  Creates a gra_character.

  ## Examples

      iex> create_gra_character(%{field: value})
      {:ok, %GraCharacter{}}

      iex> create_gra_character(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_gra_character(attrs \\ %{}) do
    %GraCharacter{}
    |> GraCharacter.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a gra_character.

  ## Examples

      iex> update_gra_character(gra_character, %{field: new_value})
      {:ok, %GraCharacter{}}

      iex> update_gra_character(gra_character, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_gra_character(%GraCharacter{} = gra_character, attrs) do
    gra_character
    |> GraCharacter.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a gra_character.

  ## Examples

      iex> delete_gra_character(gra_character)
      {:ok, %GraCharacter{}}

      iex> delete_gra_character(gra_character)
      {:error, %Ecto.Changeset{}}

  """
  def delete_gra_character(%GraCharacter{} = gra_character) do
    Repo.delete(gra_character)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking gra_character changes.

  ## Examples

      iex> change_gra_character(gra_character)
      %Ecto.Changeset{data: %GraCharacter{}}

  """
  def change_gra_character(%GraCharacter{} = gra_character, attrs \\ %{}) do
    GraCharacter.changeset(gra_character, attrs)
  end

  # Additional relationship functions
  @doc """
  Gets characters by user ID.
  """
  def get_characters_by_user(user_id) do
    GraCharacter
    |> where(user_id: ^user_id)
    |> where(soft_delete: false)
    |> Repo.all()
  end

  @doc """
  Gets public characters.
  """
  def get_public_characters do
    GraCharacter
    |> where(is_public: true)
    |> where(soft_delete: false)
    |> Repo.all()
  end
end
