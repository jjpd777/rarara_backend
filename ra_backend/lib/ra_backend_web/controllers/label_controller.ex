defmodule RaBackendWeb.LabelController do
  use RaBackendWeb, :controller

  alias RaBackend.GraLabels

  def index(conn, _params) do
    labels = GraLabels.list_active_public_labels()
    render(conn, :index, labels: labels)
  end
end
