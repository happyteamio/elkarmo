defmodule Elkarmo do
  use Application
  
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    slack_token = Application.get_env(:elkarmo, :slack_token)

    children = [
      worker(Elkarmo.Store, [Elkarmo.Karma.empty]),
      worker(Elkarmo.Slack, [slack_token])
    ]
    opts = [strategy: :one_for_one, name: Elkarmo.Supervisor]
    {:ok, _pid} = Supervisor.start_link children, opts
  end
end
