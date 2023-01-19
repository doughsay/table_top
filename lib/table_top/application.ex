defmodule TableTop.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TableTopWeb.Telemetry,
      # Start the Ecto repository
      TableTop.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: TableTop.PubSub},
      # Start Presence
      TableTopWeb.Presence,
      # Start Finch
      {Finch, name: TableTop.Finch},
      # Start the Endpoint (http/https)
      TableTopWeb.Endpoint
      # Start a worker by calling: TableTop.Worker.start_link(arg)
      # {TableTop.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TableTop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TableTopWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
