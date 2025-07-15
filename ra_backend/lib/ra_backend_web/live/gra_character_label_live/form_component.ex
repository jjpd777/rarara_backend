defmodule RaBackendWeb.GraCharacterLabelLive.FormComponent do
  use RaBackendWeb, :live_component

  alias RaBackend.GraCharacterLabels

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage gra_character_label records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="gra_character_label-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <:actions>
          <.button phx-disable-with="Saving...">Save Gra character label</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{gra_character_label: gra_character_label} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(GraCharacterLabels.change_gra_character_label(gra_character_label))
     end)}
  end

  @impl true
  def handle_event("validate", %{"gra_character_label" => gra_character_label_params}, socket) do
    changeset = GraCharacterLabels.change_gra_character_label(socket.assigns.gra_character_label, gra_character_label_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"gra_character_label" => gra_character_label_params}, socket) do
    save_gra_character_label(socket, socket.assigns.action, gra_character_label_params)
  end

  defp save_gra_character_label(socket, :edit, gra_character_label_params) do
    case GraCharacterLabels.update_gra_character_label(socket.assigns.gra_character_label, gra_character_label_params) do
      {:ok, gra_character_label} ->
        notify_parent({:saved, gra_character_label})

        {:noreply,
         socket
         |> put_flash(:info, "Gra character label updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_gra_character_label(socket, :new, gra_character_label_params) do
    case GraCharacterLabels.create_gra_character_label(gra_character_label_params) do
      {:ok, gra_character_label} ->
        notify_parent({:saved, gra_character_label})

        {:noreply,
         socket
         |> put_flash(:info, "Gra character label created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
