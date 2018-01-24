defmodule Elkarmo.Slack do
  use Slack

  def handle_connect(slack, state) do
    IO.puts("Connected as #{slack.me.name}")
    {:ok, state}
  end

  def handle_event(_message = %{type: "message", subtype: _}, _slack, state), do: {:ok, state}

  # ignore reply_to messages
  def handle_event(_message = %{type: "message", reply_to: _}, _slack, state), do: {:ok, state}

  def handle_event(message = %{type: "message"}, slack, state) do
    if not is_direct_message?(message, slack) do
      case Elkarmo.Parser.parse(message.text, slack.me.id) do
        :info -> show_karma(message, slack)
        :reset -> reset_karma(message, slack)
        {:update, changes} -> update_karma(message, slack, changes)
        _ -> :ok
      end
    else
      if message.text == "version" do
        show_version(message, slack)
      else
        show_karma(message, slack)
      end
    end

    {:ok, state}
  end

  def handle_event(_message, _slack, state), do: {:ok, state}

  defp is_direct_message?(%{channel: channel}, slack), do: Map.has_key?(slack.ims, channel)

  defp show_version(%{channel: channel}, slack) do
    {:ok, version} = :application.get_key(:elkarmo, :vsn)
    send_message(to_string(version), channel, slack)
  end

  defp show_karma(%{channel: channel}, slack) do
    msg = Elkarmo.Store.get() |> Elkarmo.Formatter.to_message()
    send_message(msg, channel, slack)
  end

  defp reset_karma(%{channel: channel}, slack) do
    Elkarmo.Store.set(Elkarmo.Karma.empty())
    send_message("Karma is gone :runner::dash:", channel, slack)
  end

  defp update_karma(%{channel: channel, user: user}, slack, changes) do
    {cheats, valid_changes} = Enum.partition(changes, &is_cheater?(user, &1))
    if cheats != [], do: send_message("<@#{user}>: :middle_finger:", channel, slack)
    current_karma = Elkarmo.Store.get()
    new_karma = Elkarmo.Karma.update(current_karma, valid_changes)
    Elkarmo.Store.set(new_karma)

    changed_users = for {user, _} <- changes, do: user
    changed_karmas = Elkarmo.Karma.get(new_karma, changed_users)

    msg = Elkarmo.Formatter.to_message(changed_karmas)
    send_message(msg, channel, slack)
  end

  defp is_cheater?(sending_user, {user, karma}), do: sending_user == user and karma > 0
end
