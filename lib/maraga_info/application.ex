defmodule MaragaInfo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MaragaInfoWeb.Telemetry,
      MaragaInfo.Repo,
      {DNSCluster, query: Application.get_env(:maraga_info, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MaragaInfo.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MaragaInfo.Finch},
      # Oban runs the bulk email delivery jobs
      {Oban, Application.fetch_env!(:maraga_info, Oban)},
      # Start to serve requests, typically the last entry
      MaragaInfoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MaragaInfo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MaragaInfoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
