defmodule RaBackendWeb.GraCharacterLive.Index do
  use RaBackendWeb, :live_view

  alias RaBackend.GraCharacters
  alias RaBackend.GraCharacters.GraCharacter

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :gra_characters, GraCharacters.list_gra_characters())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Gra character")
    |> assign(:gra_character, GraCharacters.get_gra_character!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Gra character")
    |> assign(:gra_character, %GraCharacter{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Gra characters")
    |> assign(:gra_character, nil)
  end

  @impl true
  def handle_info({RaBackendWeb.GraCharacterLive.FormComponent, {:saved, gra_character}}, socket) do
    {:noreply, stream_insert(socket, :gra_characters, gra_character)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    gra_character = GraCharacters.get_gra_character!(id)
    {:ok, _} = GraCharacters.delete_gra_character(gra_character)

    {:noreply, stream_delete(socket, :gra_characters, gra_character)}
  end
end
