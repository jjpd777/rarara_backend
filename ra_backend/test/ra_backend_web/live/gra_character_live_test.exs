defmodule RaBackendWeb.GraCharacterLiveTest do
  use RaBackendWeb.ConnCase

  import Phoenix.LiveViewTest
  import RaBackend.GraCharactersFixtures

  @create_attrs %{name: "some name", biography: "some biography", system_prompt: "some system_prompt", creation_prompt: "some creation_prompt", llm_model: "some llm_model", is_public: true, soft_delete: true}
  @update_attrs %{name: "some updated name", biography: "some updated biography", system_prompt: "some updated system_prompt", creation_prompt: "some updated creation_prompt", llm_model: "some updated llm_model", is_public: false, soft_delete: false}
  @invalid_attrs %{name: nil, biography: nil, system_prompt: nil, creation_prompt: nil, llm_model: nil, is_public: false, soft_delete: false}

  defp create_gra_character(_) do
    gra_character = gra_character_fixture()
    %{gra_character: gra_character}
  end

  describe "Index" do
    setup [:create_gra_character]

    test "lists all gra_characters", %{conn: conn, gra_character: gra_character} do
      {:ok, _index_live, html} = live(conn, ~p"/gra_characters")

      assert html =~ "Listing Gra characters"
      assert html =~ gra_character.name
    end

    test "saves new gra_character", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/gra_characters")

      assert index_live |> element("a", "New Gra character") |> render_click() =~
               "New Gra character"

      assert_patch(index_live, ~p"/gra_characters/new")

      assert index_live
             |> form("#gra_character-form", gra_character: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gra_character-form", gra_character: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gra_characters")

      html = render(index_live)
      assert html =~ "Gra character created successfully"
      assert html =~ "some name"
    end

    test "updates gra_character in listing", %{conn: conn, gra_character: gra_character} do
      {:ok, index_live, _html} = live(conn, ~p"/gra_characters")

      assert index_live |> element("#gra_characters-#{gra_character.id} a", "Edit") |> render_click() =~
               "Edit Gra character"

      assert_patch(index_live, ~p"/gra_characters/#{gra_character}/edit")

      assert index_live
             |> form("#gra_character-form", gra_character: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#gra_character-form", gra_character: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/gra_characters")

      html = render(index_live)
      assert html =~ "Gra character updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes gra_character in listing", %{conn: conn, gra_character: gra_character} do
      {:ok, index_live, _html} = live(conn, ~p"/gra_characters")

      assert index_live |> element("#gra_characters-#{gra_character.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#gra_characters-#{gra_character.id}")
    end
  end

  describe "Show" do
    setup [:create_gra_character]

    test "displays gra_character", %{conn: conn, gra_character: gra_character} do
      {:ok, _show_live, html} = live(conn, ~p"/gra_characters/#{gra_character}")

      assert html =~ "Show Gra character"
      assert html =~ gra_character.name
    end

    test "updates gra_character within modal", %{conn: conn, gra_character: gra_character} do
      {:ok, show_live, _html} = live(conn, ~p"/gra_characters/#{gra_character}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Gra character"

      assert_patch(show_live, ~p"/gra_characters/#{gra_character}/show/edit")

      assert show_live
             |> form("#gra_character-form", gra_character: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#gra_character-form", gra_character: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/gra_characters/#{gra_character}")

      html = render(show_live)
      assert html =~ "Gra character updated successfully"
      assert html =~ "some updated name"
    end
  end
end
