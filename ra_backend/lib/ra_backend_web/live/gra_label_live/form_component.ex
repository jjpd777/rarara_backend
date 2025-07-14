defmodule RaBackendWeb.GraLabelLive.FormComponent do
  use RaBackendWeb, :live_component

  alias RaBackend.GraLabels

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage gra_label records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="gra_label-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:category]} type="text" label="Category" />
        <.input field={@form[:subcategory]} type="text" label="Subcategory" />
        <.input field={@form[:color]} type="text" label="Color" />
        <.input field={@form[:icon]} type="text" label="Icon" />
        <.input field={@form[:priority]} type="number" label="Priority" />
        <.input field={@form[:is_active]} type="checkbox" label="Is active" />
        <.input field={@form[:is_public]} type="checkbox" label="Is public" />
        <.input field={@form[:soft_delete]} type="checkbox" label="Soft delete" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Gra label</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{gra_label: gra_label} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(GraLabels.change_gra_label(gra_label))
     end)}
  end

  @impl true
  def handle_event("validate", %{"gra_label" => gra_label_params}, socket) do
    changeset = GraLabels.change_gra_label(socket.assigns.gra_label, gra_label_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"gra_label" => gra_label_params}, socket) do
    save_gra_label(socket, socket.assigns.action, gra_label_params)
  end

  defp save_gra_label(socket, :edit, gra_label_params) do
    case GraLabels.update_gra_label(socket.assigns.gra_label, gra_label_params) do
      {:ok, gra_label} ->
        notify_parent({:saved, gra_label})

        {:noreply,
         socket
         |> put_flash(:info, "Gra label updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_gra_label(socket, :new, gra_label_params) do
    case GraLabels.create_gra_label(gra_label_params) do
      {:ok, gra_label} ->
        notify_parent({:saved, gra_label})

        {:noreply,
         socket
         |> put_flash(:info, "Gra label created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
