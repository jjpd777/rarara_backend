defmodule RaBackend.GraUsers.GraUser do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :metadata, :map, default: %{}
    field :apple_id, :string
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :avatar_url, :string
    field :is_active, :boolean, default: true
    field :is_verified, :boolean, default: false
    field :last_sign_in_at, :utc_datetime
    field :sign_in_count, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(gra_user, attrs) do
    gra_user
    |> cast(attrs, [:apple_id, :email, :first_name, :last_name, :avatar_url, :is_active, :is_verified, :last_sign_in_at, :sign_in_count, :metadata])
    |> validate_required([:is_active, :is_verified, :sign_in_count])
    |> validate_apple_id_or_email()
    |> unique_constraint(:apple_id)
    |> unique_constraint(:email)
    |> maybe_validate_email()
  end

  defp validate_apple_id_or_email(changeset) do
    apple_id = get_field(changeset, :apple_id)
    email = get_field(changeset, :email)

    if is_nil(apple_id) and is_nil(email) do
      add_error(changeset, :base, "Either apple_id or email must be provided")
    else
      changeset
    end
  end

  defp maybe_validate_email(changeset) do
    case get_field(changeset, :email) do
      nil -> changeset
      email -> validate_format(changeset, :email, ~r/@/)
    end
  end
end
