defmodule RaBackendWeb.GraCharacterHandleLive.Index do
  use RaBackendWeb, :live_view

  alias RaBackend.GraCharacterHandles
  alias RaBackend.GraCharacterHandles.GraCharacterHandle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :gra_character_handles, GraCharacterHandles.list_gra_character_handles())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Gra character handle")
    |> assign(:gra_character_handle, GraCharacterHandles.get_gra_character_handle!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Gra character handle")
    |> assign(:gra_character_handle, %GraCharacterHandle{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Gra character handles")
    |> assign(:gra_character_handle, nil)
  end

  @impl true
  def handle_info({RaBackendWeb.GraCharacterHandleLive.FormComponent, {:saved, gra_character_handle}}, socket) do
    {:noreply, stream_insert(socket, :gra_character_handles, gra_character_handle)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    gra_character_handle = GraCharacterHandles.get_gra_character_handle!(id)
    {:ok, _} = GraCharacterHandles.delete_gra_character_handle(gra_character_handle)

    {:noreply, stream_delete(socket, :gra_character_handles, gra_character_handle)}
  end
end
