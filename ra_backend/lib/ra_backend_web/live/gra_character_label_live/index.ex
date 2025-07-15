defmodule RaBackendWeb.GraCharacterLabelLive.Index do
  use RaBackendWeb, :live_view

  alias RaBackend.GraCharacterLabels
  alias RaBackend.GraCharacterLabels.GraCharacterLabel

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :gra_characters_gra_labels, GraCharacterLabels.list_gra_characters_gra_labels())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Gra character label")
    |> assign(:gra_character_label, GraCharacterLabels.get_gra_character_label!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Gra character label")
    |> assign(:gra_character_label, %GraCharacterLabel{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Gra characters gra labels")
    |> assign(:gra_character_label, nil)
  end

  @impl true
  def handle_info({RaBackendWeb.GraCharacterLabelLive.FormComponent, {:saved, gra_character_label}}, socket) do
    {:noreply, stream_insert(socket, :gra_characters_gra_labels, gra_character_label)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    gra_character_label = GraCharacterLabels.get_gra_character_label!(id)
    {:ok, _} = GraCharacterLabels.delete_gra_character_label(gra_character_label)

    {:noreply, stream_delete(socket, :gra_characters_gra_labels, gra_character_label)}
  end
end
