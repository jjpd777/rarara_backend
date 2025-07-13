defmodule RaBackend.GraUsersTest do
  use RaBackend.DataCase

  alias RaBackend.GraUsers

  describe "users" do
    alias RaBackend.GraUsers.GraUser

    import RaBackend.GraUsersFixtures

    @invalid_attrs %{metadata: nil, apple_id: nil, email: nil, first_name: nil, avatar_url: nil, is_active: nil, is_verified: nil, last_sign_in_at: nil, sign_in_count: nil}

    test "list_users/0 returns all users" do
      gra_user = gra_user_fixture()
      assert GraUsers.list_users() == [gra_user]
    end

    test "get_gra_user!/1 returns the gra_user with given id" do
      gra_user = gra_user_fixture()
      assert GraUsers.get_gra_user!(gra_user.id) == gra_user
    end

    test "create_gra_user/1 with valid data creates a gra_user" do
      valid_attrs = %{metadata: %{}, apple_id: "some apple_id", email: "some email", first_name: "some first_name", avatar_url: "some avatar_url", is_active: true, is_verified: true, last_sign_in_at: ~U[2025-07-12 21:49:00Z], sign_in_count: 42}

      assert {:ok, %GraUser{} = gra_user} = GraUsers.create_gra_user(valid_attrs)
      assert gra_user.metadata == %{}
      assert gra_user.apple_id == "some apple_id"
      assert gra_user.email == "some email"
      assert gra_user.first_name == "some first_name"
      assert gra_user.avatar_url == "some avatar_url"
      assert gra_user.is_active == true
      assert gra_user.is_verified == true
      assert gra_user.last_sign_in_at == ~U[2025-07-12 21:49:00Z]
      assert gra_user.sign_in_count == 42
    end

    test "create_gra_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GraUsers.create_gra_user(@invalid_attrs)
    end

    test "update_gra_user/2 with valid data updates the gra_user" do
      gra_user = gra_user_fixture()
      update_attrs = %{metadata: %{}, apple_id: "some updated apple_id", email: "some updated email", first_name: "some updated first_name", avatar_url: "some updated avatar_url", is_active: false, is_verified: false, last_sign_in_at: ~U[2025-07-13 21:49:00Z], sign_in_count: 43}

      assert {:ok, %GraUser{} = gra_user} = GraUsers.update_gra_user(gra_user, update_attrs)
      assert gra_user.metadata == %{}
      assert gra_user.apple_id == "some updated apple_id"
      assert gra_user.email == "some updated email"
      assert gra_user.first_name == "some updated first_name"
      assert gra_user.avatar_url == "some updated avatar_url"
      assert gra_user.is_active == false
      assert gra_user.is_verified == false
      assert gra_user.last_sign_in_at == ~U[2025-07-13 21:49:00Z]
      assert gra_user.sign_in_count == 43
    end

    test "update_gra_user/2 with invalid data returns error changeset" do
      gra_user = gra_user_fixture()
      assert {:error, %Ecto.Changeset{}} = GraUsers.update_gra_user(gra_user, @invalid_attrs)
      assert gra_user == GraUsers.get_gra_user!(gra_user.id)
    end

    test "delete_gra_user/1 deletes the gra_user" do
      gra_user = gra_user_fixture()
      assert {:ok, %GraUser{}} = GraUsers.delete_gra_user(gra_user)
      assert_raise Ecto.NoResultsError, fn -> GraUsers.get_gra_user!(gra_user.id) end
    end

    test "change_gra_user/1 returns a gra_user changeset" do
      gra_user = gra_user_fixture()
      assert %Ecto.Changeset{} = GraUsers.change_gra_user(gra_user)
    end
  end
end
