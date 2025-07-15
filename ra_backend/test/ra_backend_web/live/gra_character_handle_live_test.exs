defmodule RaBackendWeb.GraCharacterHandleLiveTest do
  use RaBackendWeb.ConnCase

  import Phoenix.LiveViewTest
  import RaBackend.GraCharacterHandlesFixtures

  @create_attrs %{handle_name: "some handle_name", is_primary: true, is_active: true}
  @update_attrs %{handle_name: "some updated handle_name", is_primary: false, is_active: false}
  @invalid_attrs %{handle_name: nil, is_primary: false, is_active: false}

  defp create_gra_character_handle(_) do
    gra_character_handle = gra_character_handle_fixture()
    %{gra_character_handle: gra_character_handle}
  end

  describe "Index" do
    setup [:create_gra_character_handle]

    test "lists all gra_character_handles", %{conn: conn, gra_character_handle: gra_character_handle} do
      {:ok, _index_live, html} = live(conn, ~p"/gra_character_handles")

      assert html =~ "Listing Gra character handles"
      assert html =~ gra_character_handle.handle_name
    end

    test "saves new gra_character_handle", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/gra_character_handles")

      assert index_live |> element("a", "New Gra character handle") |> render_click() =~
               "New Gra character handle"

      assert_patch(index_live, ~p"/gra_character_handles/new")

      assert index_live
             |> form("#gra_character_handle-form", gra_character_handle: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gra_character_handle-form", gra_character_handle: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gra_character_handles")

      html = render(index_live)
      assert html =~ "Gra character handle created successfully"
      assert html =~ "some handle_name"
    end

    test "updates gra_character_handle in listing", %{conn: conn, gra_character_handle: gra_character_handle} do
      {:ok, index_live, _html} = live(conn, ~p"/gra_character_handles")

      assert index_live |> element("#gra_character_handles-#{gra_character_handle.id} a", "Edit") |> render_click() =~
               "Edit Gra character handle"

      assert_patch(index_live, ~p"/gra_character_handles/#{gra_character_handle}/edit")

      assert index_live
             |> form("#gra_character_handle-form", gra_character_handle: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gra_character_handle-form", gra_character_handle: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gra_character_handles")

      html = render(index_live)
      assert html =~ "Gra character handle updated successfully"
      assert html =~ "some updated handle_name"
    end

    test "deletes gra_character_handle in listing", %{conn: conn, gra_character_handle: gra_character_handle} do
      {:ok, index_live, _html} = live(conn, ~p"/gra_character_handles")

      assert index_live |> element("#gra_character_handles-#{gra_character_handle.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#gra_character_handles-#{gra_character_handle.id}")
    end
  end

  describe "Show" do
    setup [:create_gra_character_handle]

    test "displays gra_character_handle", %{conn: conn, gra_character_handle: gra_character_handle} do
      {:ok, _show_live, html} = live(conn, ~p"/gra_character_handles/#{gra_character_handle}")

      assert html =~ "Show Gra character handle"
      assert html =~ gra_character_handle.handle_name
    end

    test "updates gra_character_handle within modal", %{conn: conn, gra_character_handle: gra_character_handle} do
      {:ok, show_live, _html} = live(conn, ~p"/gra_character_handles/#{gra_character_handle}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Gra character handle"

      assert_patch(show_live, ~p"/gra_character_handles/#{gra_character_handle}/show/edit")

      assert show_live
             |> form("#gra_character_handle-form", gra_character_handle: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#gra_character_handle-form", gra_character_handle: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/gra_character_handles/#{gra_character_handle}")

      html = render(show_live)
      assert html =~ "Gra character handle updated successfully"
      assert html =~ "some updated handle_name"
    end
  end
end
