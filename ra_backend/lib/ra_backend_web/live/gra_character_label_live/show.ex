defmodule RaBackendWeb.GraCharacterLabelLive.Show do
  use RaBackendWeb, :live_view

  alias RaBackend.GraCharacterLabels

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:gra_character_label, GraCharacterLabels.get_gra_character_label!(id))}
  end

  defp page_title(:show), do: "Show Gra character label"
  defp page_title(:edit), do: "Edit Gra character label"
end
