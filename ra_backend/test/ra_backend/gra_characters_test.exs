defmodule RaBackend.GraCharactersTest do
  use RaBackend.DataCase

  alias RaBackend.GraCharacters

  describe "gra_characters" do
    alias RaBackend.GraCharacters.GraCharacter

    import RaBackend.GraCharactersFixtures

    @invalid_attrs %{name: nil, biography: nil, system_prompt: nil, creation_prompt: nil, llm_model: nil, is_public: nil, soft_delete: nil}

    test "list_gra_characters/0 returns all gra_characters" do
      gra_character = gra_character_fixture()
      assert GraCharacters.list_gra_characters() == [gra_character]
    end

    test "get_gra_character!/1 returns the gra_character with given id" do
      gra_character = gra_character_fixture()
      assert GraCharacters.get_gra_character!(gra_character.id) == gra_character
    end

    test "create_gra_character/1 with valid data creates a gra_character" do
      valid_attrs = %{name: "some name", biography: "some biography", system_prompt: "some system_prompt", creation_prompt: "some creation_prompt", llm_model: "some llm_model", is_public: true, soft_delete: true}

      assert {:ok, %GraCharacter{} = gra_character} = GraCharacters.create_gra_character(valid_attrs)
      assert gra_character.name == "some name"
      assert gra_character.biography == "some biography"
      assert gra_character.system_prompt == "some system_prompt"
      assert gra_character.creation_prompt == "some creation_prompt"
      assert gra_character.llm_model == "some llm_model"
      assert gra_character.is_public == true
      assert gra_character.soft_delete == true
    end

    test "create_gra_character/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GraCharacters.create_gra_character(@invalid_attrs)
    end

    test "update_gra_character/2 with valid data updates the gra_character" do
      gra_character = gra_character_fixture()
      update_attrs = %{name: "some updated name", biography: "some updated biography", system_prompt: "some updated system_prompt", creation_prompt: "some updated creation_prompt", llm_model: "some updated llm_model", is_public: false, soft_delete: false}

      assert {:ok, %GraCharacter{} = gra_character} = GraCharacters.update_gra_character(gra_character, update_attrs)
      assert gra_character.name == "some updated name"
      assert gra_character.biography == "some updated biography"
      assert gra_character.system_prompt == "some updated system_prompt"
      assert gra_character.creation_prompt == "some updated creation_prompt"
      assert gra_character.llm_model == "some updated llm_model"
      assert gra_character.is_public == false
      assert gra_character.soft_delete == false
    end

    test "update_gra_character/2 with invalid data returns error changeset" do
      gra_character = gra_character_fixture()
      assert {:error, %Ecto.Changeset{}} = GraCharacters.update_gra_character(gra_character, @invalid_attrs)
      assert gra_character == GraCharacters.get_gra_character!(gra_character.id)
    end

    test "delete_gra_character/1 deletes the gra_character" do
      gra_character = gra_character_fixture()
      assert {:ok, %GraCharacter{}} = GraCharacters.delete_gra_character(gra_character)
      assert_raise Ecto.NoResultsError, fn -> GraCharacters.get_gra_character!(gra_character.id) end
    end

    test "change_gra_character/1 returns a gra_character changeset" do
      gra_character = gra_character_fixture()
      assert %Ecto.Changeset{} = GraCharacters.change_gra_character(gra_character)
    end
  end
end
