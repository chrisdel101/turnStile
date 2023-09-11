defmodule TurnStile.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    unless Mix.env == :prod do
      Dotenv.load
      Mix.Task.run("loadconfig")
    end
    children = [
      # Start the Ecto repository
      TurnStile.Repo,
      # Start the Telemetry supervisor
      TurnStileWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: TurnStile.PubSub},
      # start the action GenServer
      {TurnStile.ActionGenServer, "off"},
      # Start the Endpoint (http/https)
      TurnStileWeb.Endpoint
      # Start a worker by calling: TurnStile.Worker.start_link(arg)
      # {TurnStile.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TurnStile.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TurnStileWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
