defmodule RaBackend.GraCharacterHandlesTest do
  use RaBackend.DataCase

  alias RaBackend.GraCharacterHandles

  describe "gra_character_handles" do
    alias RaBackend.GraCharacterHandles.GraCharacterHandle

    import RaBackend.GraCharacterHandlesFixtures

    @invalid_attrs %{handle_name: nil, is_primary: nil, is_active: nil}

    test "list_gra_character_handles/0 returns all gra_character_handles" do
      gra_character_handle = gra_character_handle_fixture()
      assert GraCharacterHandles.list_gra_character_handles() == [gra_character_handle]
    end

    test "get_gra_character_handle!/1 returns the gra_character_handle with given id" do
      gra_character_handle = gra_character_handle_fixture()
      assert GraCharacterHandles.get_gra_character_handle!(gra_character_handle.id) == gra_character_handle
    end

    test "create_gra_character_handle/1 with valid data creates a gra_character_handle" do
      valid_attrs = %{handle_name: "some handle_name", is_primary: true, is_active: true}

      assert {:ok, %GraCharacterHandle{} = gra_character_handle} = GraCharacterHandles.create_gra_character_handle(valid_attrs)
      assert gra_character_handle.handle_name == "some handle_name"
      assert gra_character_handle.is_primary == true
      assert gra_character_handle.is_active == true
    end

    test "create_gra_character_handle/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GraCharacterHandles.create_gra_character_handle(@invalid_attrs)
    end

    test "update_gra_character_handle/2 with valid data updates the gra_character_handle" do
      gra_character_handle = gra_character_handle_fixture()
      update_attrs = %{handle_name: "some updated handle_name", is_primary: false, is_active: false}

      assert {:ok, %GraCharacterHandle{} = gra_character_handle} = GraCharacterHandles.update_gra_character_handle(gra_character_handle, update_attrs)
      assert gra_character_handle.handle_name == "some updated handle_name"
      assert gra_character_handle.is_primary == false
      assert gra_character_handle.is_active == false
    end

    test "update_gra_character_handle/2 with invalid data returns error changeset" do
      gra_character_handle = gra_character_handle_fixture()
      assert {:error, %Ecto.Changeset{}} = GraCharacterHandles.update_gra_character_handle(gra_character_handle, @invalid_attrs)
      assert gra_character_handle == GraCharacterHandles.get_gra_character_handle!(gra_character_handle.id)
    end

    test "delete_gra_character_handle/1 deletes the gra_character_handle" do
      gra_character_handle = gra_character_handle_fixture()
      assert {:ok, %GraCharacterHandle{}} = GraCharacterHandles.delete_gra_character_handle(gra_character_handle)
      assert_raise Ecto.NoResultsError, fn -> GraCharacterHandles.get_gra_character_handle!(gra_character_handle.id) end
    end

    test "change_gra_character_handle/1 returns a gra_character_handle changeset" do
      gra_character_handle = gra_character_handle_fixture()
      assert %Ecto.Changeset{} = GraCharacterHandles.change_gra_character_handle(gra_character_handle)
    end
  end
end
