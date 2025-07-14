defmodule RaBackend.GraLabelsTest do
  use RaBackend.DataCase

  alias RaBackend.GraLabels

  describe "labels" do
    alias RaBackend.GraLabels.GraLabel

    import RaBackend.GraLabelsFixtures

    @invalid_attrs %{name: nil, priority: nil, description: nil, metadata: nil, category: nil, color: nil, subcategory: nil, icon: nil, is_active: nil, is_public: nil, soft_delete: nil}

    test "list_labels/0 returns all labels" do
      gra_label = gra_label_fixture()
      assert GraLabels.list_labels() == [gra_label]
    end

    test "get_gra_label!/1 returns the gra_label with given id" do
      gra_label = gra_label_fixture()
      assert GraLabels.get_gra_label!(gra_label.id) == gra_label
    end

    test "create_gra_label/1 with valid data creates a gra_label" do
      valid_attrs = %{name: "some name", priority: 42, description: "some description", metadata: %{}, category: "some category", color: "some color", subcategory: "some subcategory", icon: "some icon", is_active: true, is_public: true, soft_delete: true}

      assert {:ok, %GraLabel{} = gra_label} = GraLabels.create_gra_label(valid_attrs)
      assert gra_label.name == "some name"
      assert gra_label.priority == 42
      assert gra_label.description == "some description"
      assert gra_label.metadata == %{}
      assert gra_label.category == "some category"
      assert gra_label.color == "some color"
      assert gra_label.subcategory == "some subcategory"
      assert gra_label.icon == "some icon"
      assert gra_label.is_active == true
      assert gra_label.is_public == true
      assert gra_label.soft_delete == true
    end

    test "create_gra_label/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GraLabels.create_gra_label(@invalid_attrs)
    end

    test "update_gra_label/2 with valid data updates the gra_label" do
      gra_label = gra_label_fixture()
      update_attrs = %{name: "some updated name", priority: 43, description: "some updated description", metadata: %{}, category: "some updated category", color: "some updated color", subcategory: "some updated subcategory", icon: "some updated icon", is_active: false, is_public: false, soft_delete: false}

      assert {:ok, %GraLabel{} = gra_label} = GraLabels.update_gra_label(gra_label, update_attrs)
      assert gra_label.name == "some updated name"
      assert gra_label.priority == 43
      assert gra_label.description == "some updated description"
      assert gra_label.metadata == %{}
      assert gra_label.category == "some updated category"
      assert gra_label.color == "some updated color"
      assert gra_label.subcategory == "some updated subcategory"
      assert gra_label.icon == "some updated icon"
      assert gra_label.is_active == false
      assert gra_label.is_public == false
      assert gra_label.soft_delete == false
    end

    test "update_gra_label/2 with invalid data returns error changeset" do
      gra_label = gra_label_fixture()
      assert {:error, %Ecto.Changeset{}} = GraLabels.update_gra_label(gra_label, @invalid_attrs)
      assert gra_label == GraLabels.get_gra_label!(gra_label.id)
    end

    test "delete_gra_label/1 deletes the gra_label" do
      gra_label = gra_label_fixture()
      assert {:ok, %GraLabel{}} = GraLabels.delete_gra_label(gra_label)
      assert_raise Ecto.NoResultsError, fn -> GraLabels.get_gra_label!(gra_label.id) end
    end

    test "change_gra_label/1 returns a gra_label changeset" do
      gra_label = gra_label_fixture()
      assert %Ecto.Changeset{} = GraLabels.change_gra_label(gra_label)
    end
  end
end
