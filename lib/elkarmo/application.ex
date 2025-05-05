defmodule Elkarmo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Elkarmo.Worker.start_link(arg)
      {Elkarmo.Store, Elkarmo.Karma.empty()},
      {Slack.Supervisor, Application.fetch_env!(:elkarmo, Elkarmo.Slack)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Elkarmo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
