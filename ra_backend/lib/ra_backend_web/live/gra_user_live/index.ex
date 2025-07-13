defmodule RaBackendWeb.GraUserLive.Index do
  use RaBackendWeb, :live_view

  alias RaBackend.GraUsers
  alias RaBackend.GraUsers.GraUser

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :users, GraUsers.list_users())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Gra user")
    |> assign(:gra_user, GraUsers.get_gra_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Gra user")
    |> assign(:gra_user, %GraUser{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:gra_user, nil)
  end

  @impl true
  def handle_info({RaBackendWeb.GraUserLive.FormComponent, {:saved, gra_user}}, socket) do
    {:noreply, stream_insert(socket, :users, gra_user)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    gra_user = GraUsers.get_gra_user!(id)
    {:ok, _} = GraUsers.delete_gra_user(gra_user)

    {:noreply, stream_delete(socket, :users, gra_user)}
  end
end
