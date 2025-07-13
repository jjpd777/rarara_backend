defmodule RaBackend.GraUsers do
  @moduledoc """
  The GraUsers context.
  """

  import Ecto.Query, warn: false
  alias RaBackend.Repo

  alias RaBackend.GraUsers.GraUser

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%GraUser{}, ...]

  """
  def list_users do
    Repo.all(GraUser)
  end

  @doc """
  Gets a single gra_user.

  Raises `Ecto.NoResultsError` if the Gra user does not exist.

  ## Examples

      iex> get_gra_user!(123)
      %GraUser{}

      iex> get_gra_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_gra_user!(id), do: Repo.get!(GraUser, id)

  @doc """
  Creates a gra_user.

  ## Examples

      iex> create_gra_user(%{field: value})
      {:ok, %GraUser{}}

      iex> create_gra_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_gra_user(attrs \\ %{}) do
    %GraUser{}
    |> GraUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a gra_user.

  ## Examples

      iex> update_gra_user(gra_user, %{field: new_value})
      {:ok, %GraUser{}}

      iex> update_gra_user(gra_user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_gra_user(%GraUser{} = gra_user, attrs) do
    gra_user
    |> GraUser.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a gra_user.

  ## Examples

      iex> delete_gra_user(gra_user)
      {:ok, %GraUser{}}

      iex> delete_gra_user(gra_user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_gra_user(%GraUser{} = gra_user) do
    Repo.delete(gra_user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking gra_user changes.

  ## Examples

      iex> change_gra_user(gra_user)
      %Ecto.Changeset{data: %GraUser{}}

  """
  def change_gra_user(%GraUser{} = gra_user, attrs \\ %{}) do
    GraUser.changeset(gra_user, attrs)
  end
end
