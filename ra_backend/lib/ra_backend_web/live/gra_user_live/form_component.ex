defmodule RaBackendWeb.GraUserLive.FormComponent do
  use RaBackendWeb, :live_component

  alias RaBackend.GraUsers

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage gra_user records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="gra_user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:apple_id]} type="text" label="Apple" />
        <.input field={@form[:email]} type="text" label="Email" />
        <.input field={@form[:first_name]} type="text" label="First name" />
        <.input field={@form[:avatar_url]} type="text" label="Avatar url" />
        <.input field={@form[:is_active]} type="checkbox" label="Is active" />
        <.input field={@form[:is_verified]} type="checkbox" label="Is verified" />
        <.input field={@form[:last_sign_in_at]} type="datetime-local" label="Last sign in at" />
        <.input field={@form[:sign_in_count]} type="number" label="Sign in count" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Gra user</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{gra_user: gra_user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(GraUsers.change_gra_user(gra_user))
     end)}
  end

  @impl true
  def handle_event("validate", %{"gra_user" => gra_user_params}, socket) do
    changeset = GraUsers.change_gra_user(socket.assigns.gra_user, gra_user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"gra_user" => gra_user_params}, socket) do
    save_gra_user(socket, socket.assigns.action, gra_user_params)
  end

  defp save_gra_user(socket, :edit, gra_user_params) do
    case GraUsers.update_gra_user(socket.assigns.gra_user, gra_user_params) do
      {:ok, gra_user} ->
        notify_parent({:saved, gra_user})

        {:noreply,
         socket
         |> put_flash(:info, "Gra user updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_gra_user(socket, :new, gra_user_params) do
    case GraUsers.create_gra_user(gra_user_params) do
      {:ok, gra_user} ->
        notify_parent({:saved, gra_user})

        {:noreply,
         socket
         |> put_flash(:info, "Gra user created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
