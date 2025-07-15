defmodule RaBackendWeb.GraCharacterLabelLiveTest do
  use RaBackendWeb.ConnCase

  import Phoenix.LiveViewTest
  import RaBackend.GraCharacterLabelsFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_gra_character_label(_) do
    gra_character_label = gra_character_label_fixture()
    %{gra_character_label: gra_character_label}
  end

  describe "Index" do
    setup [:create_gra_character_label]

    test "lists all gra_characters_gra_labels", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/gra_characters_gra_labels")

      assert html =~ "Listing Gra characters gra labels"
    end

    test "saves new gra_character_label", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/gra_characters_gra_labels")

      assert index_live |> element("a", "New Gra character label") |> render_click() =~
               "New Gra character label"

      assert_patch(index_live, ~p"/gra_characters_gra_labels/new")

      assert index_live
             |> form("#gra_character_label-form", gra_character_label: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gra_character_label-form", gra_character_label: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gra_characters_gra_labels")

      html = render(index_live)
      assert html =~ "Gra character label created successfully"
    end

    test "updates gra_character_label in listing", %{conn: conn, gra_character_label: gra_character_label} do
      {:ok, index_live, _html} = live(conn, ~p"/gra_characters_gra_labels")

      assert index_live |> element("#gra_characters_gra_labels-#{gra_character_label.id} a", "Edit") |> render_click() =~
               "Edit Gra character label"

      assert_patch(index_live, ~p"/gra_characters_gra_labels/#{gra_character_label}/edit")

      assert index_live
             |> form("#gra_character_label-form", gra_character_label: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gra_character_label-form", gra_character_label: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gra_characters_gra_labels")

      html = render(index_live)
      assert html =~ "Gra character label updated successfully"
    end

    test "deletes gra_character_label in listing", %{conn: conn, gra_character_label: gra_character_label} do
      {:ok, index_live, _html} = live(conn, ~p"/gra_characters_gra_labels")

      assert index_live |> element("#gra_characters_gra_labels-#{gra_character_label.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#gra_characters_gra_labels-#{gra_character_label.id}")
    end
  end

  describe "Show" do
    setup [:create_gra_character_label]

    test "displays gra_character_label", %{conn: conn, gra_character_label: gra_character_label} do
      {:ok, _show_live, html} = live(conn, ~p"/gra_characters_gra_labels/#{gra_character_label}")

      assert html =~ "Show Gra character label"
    end

    test "updates gra_character_label within modal", %{conn: conn, gra_character_label: gra_character_label} do
      {:ok, show_live, _html} = live(conn, ~p"/gra_characters_gra_labels/#{gra_character_label}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Gra character label"

      assert_patch(show_live, ~p"/gra_characters_gra_labels/#{gra_character_label}/show/edit")

      assert show_live
             |> form("#gra_character_label-form", gra_character_label: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#gra_character_label-form", gra_character_label: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/gra_characters_gra_labels/#{gra_character_label}")

      html = render(show_live)
      assert html =~ "Gra character label updated successfully"
    end
  end
end
