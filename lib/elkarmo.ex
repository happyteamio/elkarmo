defmodule Elkarmo do
  use Application

  def start(_type, _args) do
    env = Application.get_env(:elkarmo, :env)

    opts = [strategy: :one_for_one, name: Elkarmo.Supervisor]
    {:ok, _pid} = Supervisor.start_link(children(env), opts)
  end

  defp children(:test) do
    [{Elkarmo.Store, Elkarmo.Karma.empty()}]
  end

  defp children(_env) do
    slack_token =
      System.get_env("ELKARMO_SLACK_TOKEN") || Application.get_env(:elkarmo, :slack_token)

    slack_spec = %{
      id: Slack.Bot,
      start: {Slack.Bot, :start_link, [Elkarmo.Slack, [], slack_token]}
    }

    [
      {Elkarmo.Store, Elkarmo.Karma.empty()},
      slack_spec
    ]
  end
end
