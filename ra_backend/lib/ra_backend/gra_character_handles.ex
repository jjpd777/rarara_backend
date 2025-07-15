defmodule RaBackend.GraCharacterHandles do
  @moduledoc """
  The GraCharacterHandles context.
  """

  import Ecto.Query, warn: false
  alias RaBackend.Repo

  alias RaBackend.GraCharacterHandles.GraCharacterHandle

  @doc """
  Returns the list of gra_character_handles.

  ## Examples

      iex> list_gra_character_handles()
      [%GraCharacterHandle{}, ...]

  """
  def list_gra_character_handles do
    Repo.all(GraCharacterHandle)
  end

  @doc """
  Gets a single gra_character_handle.

  Raises `Ecto.NoResultsError` if the Gra character handle does not exist.

  ## Examples

      iex> get_gra_character_handle!(123)
      %GraCharacterHandle{}

      iex> get_gra_character_handle!(456)
      ** (Ecto.NoResultsError)

  """
  def get_gra_character_handle!(id), do: Repo.get!(GraCharacterHandle, id)

  @doc """
  Creates a gra_character_handle.

  ## Examples

      iex> create_gra_character_handle(%{field: value})
      {:ok, %GraCharacterHandle{}}

      iex> create_gra_character_handle(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_gra_character_handle(attrs \\ %{}) do
    %GraCharacterHandle{}
    |> GraCharacterHandle.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a gra_character_handle.

  ## Examples

      iex> update_gra_character_handle(gra_character_handle, %{field: new_value})
      {:ok, %GraCharacterHandle{}}

      iex> update_gra_character_handle(gra_character_handle, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_gra_character_handle(%GraCharacterHandle{} = gra_character_handle, attrs) do
    gra_character_handle
    |> GraCharacterHandle.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a gra_character_handle.

  ## Examples

      iex> delete_gra_character_handle(gra_character_handle)
      {:ok, %GraCharacterHandle{}}

      iex> delete_gra_character_handle(gra_character_handle)
      {:error, %Ecto.Changeset{}}

  """
  def delete_gra_character_handle(%GraCharacterHandle{} = gra_character_handle) do
    Repo.delete(gra_character_handle)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking gra_character_handle changes.

  ## Examples

      iex> change_gra_character_handle(gra_character_handle)
      %Ecto.Changeset{data: %GraCharacterHandle{}}

  """
  def change_gra_character_handle(%GraCharacterHandle{} = gra_character_handle, attrs \\ %{}) do
    GraCharacterHandle.changeset(gra_character_handle, attrs)
  end
end
