defmodule RaBackendWeb.Plugs.UserIdPlug do
  @moduledoc """
  Plug to extract user_id for API requests.
  Supports multiple identification methods in order of preference:
  1. X-User-ID header (for authenticated clients)
  2. Fallback to hardcoded dev user for development
  """

  import Plug.Conn
  require Logger

  @dev_user_id "11111111-1111-1111-1111-111111111111"

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_user_id(conn)
    assign(conn, :current_user_id, user_id)
  end

  defp get_user_id(conn) do
    case get_req_header(conn, "x-user-id") do
      [user_id] when is_binary(user_id) and user_id != "" ->
        case Ecto.UUID.cast(user_id) do
          {:ok, valid_uuid} ->
            Logger.debug("Using X-User-ID header: #{valid_uuid}")
            valid_uuid
          :error ->
            Logger.warn("Invalid UUID in X-User-ID header: #{user_id}, falling back to dev user")
            @dev_user_id
        end

      _ ->
        Logger.debug("No X-User-ID header found, using dev user: #{@dev_user_id}")
        @dev_user_id
    end
  end

  @doc """
  Helper function to get the current user ID from conn assigns.
  """
  def current_user_id(conn) do
    Map.get(conn.assigns, :current_user_id, @dev_user_id)
  end
end
