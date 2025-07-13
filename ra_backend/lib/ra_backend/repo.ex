defmodule RaBackend.Repo do
  use Ecto.Repo,
    otp_app: :ra_backend,
    adapter: Ecto.Adapters.Postgres
end
