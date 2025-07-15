defmodule RaBackendWeb.GraCharacterLive.FormComponent do
  use RaBackendWeb, :live_component

  alias RaBackend.GraCharacters

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage gra_character records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="gra_character-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:biography]} type="text" label="Biography" />
        <.input field={@form[:system_prompt]} type="text" label="System prompt" />
        <.input field={@form[:creation_prompt]} type="text" label="Creation prompt" />
        <.input field={@form[:llm_model]} type="text" label="Llm model" />
        <.input field={@form[:is_public]} type="checkbox" label="Is public" />
        <.input field={@form[:soft_delete]} type="checkbox" label="Soft delete" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Gra character</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{gra_character: gra_character} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(GraCharacters.change_gra_character(gra_character))
     end)}
  end

  @impl true
  def handle_event("validate", %{"gra_character" => gra_character_params}, socket) do
    changeset = GraCharacters.change_gra_character(socket.assigns.gra_character, gra_character_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"gra_character" => gra_character_params}, socket) do
    save_gra_character(socket, socket.assigns.action, gra_character_params)
  end

  defp save_gra_character(socket, :edit, gra_character_params) do
    case GraCharacters.update_gra_character(socket.assigns.gra_character, gra_character_params) do
      {:ok, gra_character} ->
        notify_parent({:saved, gra_character})

        {:noreply,
         socket
         |> put_flash(:info, "Gra character updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_gra_character(socket, :new, gra_character_params) do
    case GraCharacters.create_gra_character(gra_character_params) do
      {:ok, gra_character} ->
        notify_parent({:saved, gra_character})

        {:noreply,
         socket
         |> put_flash(:info, "Gra character created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
