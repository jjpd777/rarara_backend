defmodule RaBackendWeb.GraUserLiveTest do
  use RaBackendWeb.ConnCase

  import Phoenix.LiveViewTest
  import RaBackend.GraUsersFixtures

  @create_attrs %{metadata: %{}, apple_id: "some apple_id", email: "some email", first_name: "some first_name", avatar_url: "some avatar_url", is_active: true, is_verified: true, last_sign_in_at: "2025-07-12T21:49:00Z", sign_in_count: 42}
  @update_attrs %{metadata: %{}, apple_id: "some updated apple_id", email: "some updated email", first_name: "some updated first_name", avatar_url: "some updated avatar_url", is_active: false, is_verified: false, last_sign_in_at: "2025-07-13T21:49:00Z", sign_in_count: 43}
  @invalid_attrs %{metadata: nil, apple_id: nil, email: nil, first_name: nil, avatar_url: nil, is_active: false, is_verified: false, last_sign_in_at: nil, sign_in_count: nil}

  defp create_gra_user(_) do
    gra_user = gra_user_fixture()
    %{gra_user: gra_user}
  end

  describe "Index" do
    setup [:create_gra_user]

    test "lists all users", %{conn: conn, gra_user: gra_user} do
      {:ok, _index_live, html} = live(conn, ~p"/users")

      assert html =~ "Listing Users"
      assert html =~ gra_user.apple_id
    end

    test "saves new gra_user", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/users")

      assert index_live |> element("a", "New Gra user") |> render_click() =~
               "New Gra user"

      assert_patch(index_live, ~p"/users/new")

      assert index_live
             |> form("#gra_user-form", gra_user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gra_user-form", gra_user: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/users")

      html = render(index_live)
      assert html =~ "Gra user created successfully"
      assert html =~ "some apple_id"
    end

    test "updates gra_user in listing", %{conn: conn, gra_user: gra_user} do
      {:ok, index_live, _html} = live(conn, ~p"/users")

      assert index_live |> element("#users-#{gra_user.id} a", "Edit") |> render_click() =~
               "Edit Gra user"

      assert_patch(index_live, ~p"/users/#{gra_user}/edit")

      assert index_live
             |> form("#gra_user-form", gra_user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gra_user-form", gra_user: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/users")

      html = render(index_live)
      assert html =~ "Gra user updated successfully"
      assert html =~ "some updated apple_id"
    end

    test "deletes gra_user in listing", %{conn: conn, gra_user: gra_user} do
      {:ok, index_live, _html} = live(conn, ~p"/users")

      assert index_live |> element("#users-#{gra_user.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#users-#{gra_user.id}")
    end
  end

  describe "Show" do
    setup [:create_gra_user]

    test "displays gra_user", %{conn: conn, gra_user: gra_user} do
      {:ok, _show_live, html} = live(conn, ~p"/users/#{gra_user}")

      assert html =~ "Show Gra user"
      assert html =~ gra_user.apple_id
    end

    test "updates gra_user within modal", %{conn: conn, gra_user: gra_user} do
      {:ok, show_live, _html} = live(conn, ~p"/users/#{gra_user}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Gra user"

      assert_patch(show_live, ~p"/users/#{gra_user}/show/edit")

      assert show_live
             |> form("#gra_user-form", gra_user: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#gra_user-form", gra_user: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/users/#{gra_user}")

      html = render(show_live)
      assert html =~ "Gra user updated successfully"
      assert html =~ "some updated apple_id"
    end
  end
end
