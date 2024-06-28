defmodule Blogpub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BlogpubWeb.Telemetry,
      Blogpub.Repo,
      {Task, &Blogpub.Release.migrate/0},
      {Oban, Application.fetch_env!(:blogpub, Oban)},
      {Phoenix.PubSub, name: Blogpub.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Blogpub.Finch},
      # Start a worker by calling: Blogpub.Worker.start_link(arg)
      # {Blogpub.Worker, arg},
      # Start to serve requests, typically the last entry
      BlogpubWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Blogpub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BlogpubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
