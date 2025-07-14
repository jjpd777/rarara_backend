defmodule RaBackendWeb.GraLabelLiveTest do
  use RaBackendWeb.ConnCase

  import Phoenix.LiveViewTest
  import RaBackend.GraLabelsFixtures

  @create_attrs %{name: "some name", priority: 42, description: "some description", metadata: %{}, category: "some category", color: "some color", subcategory: "some subcategory", icon: "some icon", is_active: true, is_public: true, soft_delete: true}
  @update_attrs %{name: "some updated name", priority: 43, description: "some updated description", metadata: %{}, category: "some updated category", color: "some updated color", subcategory: "some updated subcategory", icon: "some updated icon", is_active: false, is_public: false, soft_delete: false}
  @invalid_attrs %{name: nil, priority: nil, description: nil, metadata: nil, category: nil, color: nil, subcategory: nil, icon: nil, is_active: false, is_public: false, soft_delete: false}

  defp create_gra_label(_) do
    gra_label = gra_label_fixture()
    %{gra_label: gra_label}
  end

  describe "Index" do
    setup [:create_gra_label]

    test "lists all labels", %{conn: conn, gra_label: gra_label} do
      {:ok, _index_live, html} = live(conn, ~p"/labels")

      assert html =~ "Listing Labels"
      assert html =~ gra_label.name
    end

    test "saves new gra_label", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/labels")

      assert index_live |> element("a", "New Gra label") |> render_click() =~
               "New Gra label"

      assert_patch(index_live, ~p"/labels/new")

      assert index_live
             |> form("#gra_label-form", gra_label: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gra_label-form", gra_label: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/labels")

      html = render(index_live)
      assert html =~ "Gra label created successfully"
      assert html =~ "some name"
    end

    test "updates gra_label in listing", %{conn: conn, gra_label: gra_label} do
      {:ok, index_live, _html} = live(conn, ~p"/labels")

      assert index_live |> element("#labels-#{gra_label.id} a", "Edit") |> render_click() =~
               "Edit Gra label"

      assert_patch(index_live, ~p"/labels/#{gra_label}/edit")

      assert index_live
             |> form("#gra_label-form", gra_label: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gra_label-form", gra_label: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/labels")

      html = render(index_live)
      assert html =~ "Gra label updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes gra_label in listing", %{conn: conn, gra_label: gra_label} do
      {:ok, index_live, _html} = live(conn, ~p"/labels")

      assert index_live |> element("#labels-#{gra_label.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#labels-#{gra_label.id}")
    end
  end

  describe "Show" do
    setup [:create_gra_label]

    test "displays gra_label", %{conn: conn, gra_label: gra_label} do
      {:ok, _show_live, html} = live(conn, ~p"/labels/#{gra_label}")

      assert html =~ "Show Gra label"
      assert html =~ gra_label.name
    end

    test "updates gra_label within modal", %{conn: conn, gra_label: gra_label} do
      {:ok, show_live, _html} = live(conn, ~p"/labels/#{gra_label}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Gra label"

      assert_patch(show_live, ~p"/labels/#{gra_label}/show/edit")

      assert show_live
             |> form("#gra_label-form", gra_label: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#gra_label-form", gra_label: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/labels/#{gra_label}")

      html = render(show_live)
      assert html =~ "Gra label updated successfully"
      assert html =~ "some updated name"
    end
  end
end
