defmodule RaBackend.GraLabels do
  @moduledoc """
  The GraLabels context.
  """

  import Ecto.Query, warn: false
  alias RaBackend.Repo

  alias RaBackend.GraLabels.GraLabel

  @doc """
  Returns the list of labels with associations.
  """
  def list_labels do
    Repo.all(from l in GraLabel, preload: [:created_by_user, :updated_by_user])
  end

  @doc """
  Gets a single gra_label with associations.
  """
  def get_gra_label!(id) do
    Repo.get!(GraLabel, id) |> Repo.preload([:created_by_user, :updated_by_user])
  end

  @doc """
  Creates a gra_label.

  ## Examples

      iex> create_gra_label(%{field: value})
      {:ok, %GraLabel{}}

      iex> create_gra_label(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_gra_label(attrs \\ %{}) do
    %GraLabel{}
    |> GraLabel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a gra_label.

  ## Examples

      iex> update_gra_label(gra_label, %{field: new_value})
      {:ok, %GraLabel{}}

      iex> update_gra_label(gra_label, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_gra_label(%GraLabel{} = gra_label, attrs) do
    gra_label
    |> GraLabel.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a gra_label.

  ## Examples

      iex> delete_gra_label(gra_label)
      {:ok, %GraLabel{}}

      iex> delete_gra_label(gra_label)
      {:error, %Ecto.Changeset{}}

  """
  def delete_gra_label(%GraLabel{} = gra_label) do
    Repo.delete(gra_label)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking gra_label changes.

  ## Examples

      iex> change_gra_label(gra_label)
      %Ecto.Changeset{data: %GraLabel{}}

  """
  def change_gra_label(%GraLabel{} = gra_label, attrs \\ %{}) do
    GraLabel.changeset(gra_label, attrs)
  end
end
