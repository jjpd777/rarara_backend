defmodule RaBackendWeb.GraCharacterLive.Show do
  use RaBackendWeb, :live_view

  alias RaBackend.GraCharacters

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:gra_character, GraCharacters.get_gra_character!(id))}
  end

  defp page_title(:show), do: "Show Gra character"
  defp page_title(:edit), do: "Edit Gra character"
end
