defmodule RaBackendWeb.GraCharacterHandleLive.Show do
  use RaBackendWeb, :live_view

  alias RaBackend.GraCharacterHandles

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:gra_character_handle, GraCharacterHandles.get_gra_character_handle!(id))}
  end

  defp page_title(:show), do: "Show Gra character handle"
  defp page_title(:edit), do: "Edit Gra character handle"
end
