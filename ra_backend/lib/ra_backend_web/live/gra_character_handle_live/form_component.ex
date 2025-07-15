defmodule RaBackendWeb.GraCharacterHandleLive.FormComponent do
  use RaBackendWeb, :live_component

  alias RaBackend.GraCharacterHandles

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage gra_character_handle records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="gra_character_handle-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:handle_name]} type="text" label="Handle name" />
        <.input field={@form[:is_primary]} type="checkbox" label="Is primary" />
        <.input field={@form[:is_active]} type="checkbox" label="Is active" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Gra character handle</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{gra_character_handle: gra_character_handle} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(GraCharacterHandles.change_gra_character_handle(gra_character_handle))
     end)}
  end

  @impl true
  def handle_event("validate", %{"gra_character_handle" => gra_character_handle_params}, socket) do
    changeset = GraCharacterHandles.change_gra_character_handle(socket.assigns.gra_character_handle, gra_character_handle_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"gra_character_handle" => gra_character_handle_params}, socket) do
    save_gra_character_handle(socket, socket.assigns.action, gra_character_handle_params)
  end

  defp save_gra_character_handle(socket, :edit, gra_character_handle_params) do
    case GraCharacterHandles.update_gra_character_handle(socket.assigns.gra_character_handle, gra_character_handle_params) do
      {:ok, gra_character_handle} ->
        notify_parent({:saved, gra_character_handle})

        {:noreply,
         socket
         |> put_flash(:info, "Gra character handle updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_gra_character_handle(socket, :new, gra_character_handle_params) do
    case GraCharacterHandles.create_gra_character_handle(gra_character_handle_params) do
      {:ok, gra_character_handle} ->
        notify_parent({:saved, gra_character_handle})

        {:noreply,
         socket
         |> put_flash(:info, "Gra character handle created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
