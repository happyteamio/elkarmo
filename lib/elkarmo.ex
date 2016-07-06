defmodule Elkarmo do
  use Application
  
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Elkarmo.Store, [Elkarmo.Karma.empty]),
      worker(Elkarmo.Slack, [""])
    ]
    opts = [strategy: :one_for_one, name: Elkarmo.Supervisor]
    {:ok, _pid} = Supervisor.start_link children, opts
  end
end
