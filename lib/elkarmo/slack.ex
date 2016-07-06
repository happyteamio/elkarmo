defmodule Elkarmo.Slack do
  alias Elkarmo.Karma
  use Slack
  require IEx

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_message(_message = %{type: "message", subtype: _}, _slack, state), do: {:ok, state}

  def handle_message(message = %{type: "message"}, slack, state) do
    if not is_direct_message?(message, slack) do
      case Elkarmo.Parser.parse(message.text, slack.me.id) do
        {:info} -> show_karma(message, slack, state)
        {:reset} -> reset_karma(message, slack, state)
        {:update, changes} -> update_karma(message, slack, state, changes)
        _ -> {:ok, state}
      end
    else
      show_karma(message, slack, state)
    end
  end

  def handle_message(_message, _slack, state), do: {:ok, state}

  defp show_karma(%{channel: channel}, slack, karma) do
    msg = Elkarmo.Formatter.to_message karma
    send_message(msg, channel, slack)
    {:ok, karma}
  end

  defp reset_karma(%{channel: channel}, slack, _karma) do
    send_message("Karma is gone :runner::dash:", channel, slack)
    {:ok, Karma.empty}
  end

  defp update_karma(%{channel: channel, user: user}, slack, current_karma, changes) do
    {cheats, valid_changes} = Enum.partition(changes, &(is_cheater?(user, &1)))
    if cheats != [], do: send_message("<@#{user}>: :middle_finger:", channel, slack)
    new_karma = Karma.update(current_karma, valid_changes)

    changed_users = for {user, _} <- changes, do: user
    changed_karmas = Karma.get(new_karma, changed_users)

    msg = Elkarmo.Formatter.to_message changed_karmas
    send_message(msg, channel, slack)

    {:ok, new_karma}
  end

  defp is_cheater?(sending_user, {user, karma}), do: sending_user == user and karma > 0

  defp is_direct_message?(%{channel: channel}, slack), do: Map.has_key? slack.ims, channel
end
