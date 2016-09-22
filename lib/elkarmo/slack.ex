defmodule Elkarmo.Slack do
  use Slack

  def handle_connect(slack) do
    IO.puts "Connected as #{slack.me.name}"
  end

  def handle_message(_message = %{type: "message", subtype: _}, _slack), do: :ok

  # ignore reply_to messages
  def handle_message(_message = %{type: "message", reply_to: _}, _slack), do: :ok

  def handle_message(message = %{type: "message"}, slack) do
    if not is_direct_message?(message, slack) do
      case Elkarmo.Parser.parse(message.text, slack.me.id) do
        :info -> show_karma(message, slack)
        :reset -> reset_karma(message, slack)
        {:update, changes} -> update_karma(message, slack, changes)
        _ -> :ok
      end
    else
      show_karma(message, slack)
    end
  end

  def handle_message(_message, _slack), do: :ok

  defp is_direct_message?(%{channel: channel}, slack), do: Map.has_key? slack.ims, channel

  defp show_karma(%{channel: channel}, slack) do
    msg = Elkarmo.Store.get |> Elkarmo.Formatter.to_message
    send_message(msg, channel, slack)
    :ok
  end

  defp reset_karma(%{channel: channel}, slack) do
    Elkarmo.Store.set Elkarmo.Karma.empty
    send_message("Karma is gone :runner::dash:", channel, slack)
    :ok
  end

  defp update_karma(%{channel: channel, user: user}, slack, changes) do
    {cheats, valid_changes} = Enum.partition(changes, &(is_cheater?(user, &1)))
    if cheats != [], do: send_message("<@#{user}>: :middle_finger:", channel, slack)
    current_karma = Elkarmo.Store.get
    new_karma = Elkarmo.Karma.update(current_karma, valid_changes)
    Elkarmo.Store.set new_karma

    changed_users = for {user, _} <- changes, do: user
    changed_karmas = Elkarmo.Karma.get(new_karma, changed_users)

    msg = Elkarmo.Formatter.to_message changed_karmas
    send_message(msg, channel, slack)
    :ok
  end

  defp is_cheater?(sending_user, {user, karma}), do: sending_user == user and karma > 0
end