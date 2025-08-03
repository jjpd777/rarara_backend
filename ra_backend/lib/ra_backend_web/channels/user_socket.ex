defmodule RaBackendWeb.UserSocket do
  @moduledoc """
  WebSocket handler for task-related real-time communication.
  Uses hardcoded authentication for development simplicity.
  """

  use Phoenix.Socket

  # Define channels
  channel "task:*", RaBackendWeb.TaskChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    # Hardcoded development user - leverages pattern matching
    dev_user_id = RaBackend.Tasks.dev_user_id()
    {:ok, assign(socket, :user_id, dev_user_id)}
  end

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
