defmodule RaBackendWeb.GraLabelLive.Index do
  use RaBackendWeb, :live_view

  alias RaBackend.GraLabels
  alias RaBackend.GraLabels.GraLabel

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :labels, GraLabels.list_labels())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Label")
    |> assign(:gra_label, GraLabels.get_gra_label!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Label")
    |> assign(:gra_label, %GraLabel{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Labels")
    |> assign(:gra_label, nil)
  end

  @impl true
  def handle_info({RaBackendWeb.GraLabelLive.FormComponent, {:saved, gra_label}}, socket) do
    {:noreply, stream_insert(socket, :labels, gra_label)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    gra_label = GraLabels.get_gra_label!(id)
    {:ok, _} = GraLabels.delete_gra_label(gra_label)

    {:noreply, stream_delete(socket, :labels, gra_label)}
  end
end
