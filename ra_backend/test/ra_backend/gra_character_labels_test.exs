defmodule RaBackend.GraCharacterLabelsTest do
  use RaBackend.DataCase

  alias RaBackend.GraCharacterLabels

  describe "gra_characters_gra_labels" do
    alias RaBackend.GraCharacterLabels.GraCharacterLabel

    import RaBackend.GraCharacterLabelsFixtures

    @invalid_attrs %{}

    test "list_gra_characters_gra_labels/0 returns all gra_characters_gra_labels" do
      gra_character_label = gra_character_label_fixture()
      assert GraCharacterLabels.list_gra_characters_gra_labels() == [gra_character_label]
    end

    test "get_gra_character_label!/1 returns the gra_character_label with given id" do
      gra_character_label = gra_character_label_fixture()
      assert GraCharacterLabels.get_gra_character_label!(gra_character_label.id) == gra_character_label
    end

    test "create_gra_character_label/1 with valid data creates a gra_character_label" do
      valid_attrs = %{}

      assert {:ok, %GraCharacterLabel{} = gra_character_label} = GraCharacterLabels.create_gra_character_label(valid_attrs)
    end

    test "create_gra_character_label/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GraCharacterLabels.create_gra_character_label(@invalid_attrs)
    end

    test "update_gra_character_label/2 with valid data updates the gra_character_label" do
      gra_character_label = gra_character_label_fixture()
      update_attrs = %{}

      assert {:ok, %GraCharacterLabel{} = gra_character_label} = GraCharacterLabels.update_gra_character_label(gra_character_label, update_attrs)
    end

    test "update_gra_character_label/2 with invalid data returns error changeset" do
      gra_character_label = gra_character_label_fixture()
      assert {:error, %Ecto.Changeset{}} = GraCharacterLabels.update_gra_character_label(gra_character_label, @invalid_attrs)
      assert gra_character_label == GraCharacterLabels.get_gra_character_label!(gra_character_label.id)
    end

    test "delete_gra_character_label/1 deletes the gra_character_label" do
      gra_character_label = gra_character_label_fixture()
      assert {:ok, %GraCharacterLabel{}} = GraCharacterLabels.delete_gra_character_label(gra_character_label)
      assert_raise Ecto.NoResultsError, fn -> GraCharacterLabels.get_gra_character_label!(gra_character_label.id) end
    end

    test "change_gra_character_label/1 returns a gra_character_label changeset" do
      gra_character_label = gra_character_label_fixture()
      assert %Ecto.Changeset{} = GraCharacterLabels.change_gra_character_label(gra_character_label)
    end
  end
end
