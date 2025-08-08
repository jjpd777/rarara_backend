defmodule RaBackend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RaBackendWeb.Telemetry,
      RaBackend.Repo,
      {DNSCluster, query: Application.get_env(:ra_backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RaBackend.PubSub, adapter: Phoenix.PubSub.PG2},
      # Start Oban for background job processing
      {Oban, Application.fetch_env!(:ra_backend, Oban)},
      # Start the Finch HTTP client for sending emails
      {Finch, name: RaBackend.Finch},
      # Start a worker by calling: RaBackend.Worker.start_link(arg)
      # {RaBackend.Worker, arg},
      # Start to serve requests, typically the last entry
      RaBackendWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RaBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RaBackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
