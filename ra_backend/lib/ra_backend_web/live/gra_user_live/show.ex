defmodule RaBackendWeb.GraUserLive.Show do
  use RaBackendWeb, :live_view

  alias RaBackend.GraUsers

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:gra_user, GraUsers.get_gra_user!(id))}
  end

  defp page_title(:show), do: "Show Gra user"
  defp page_title(:edit), do: "Edit Gra user"
end
