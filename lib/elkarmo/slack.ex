defmodule Elkarmo.Slack do
  use Slack.Bot

  require Logger

  defmodule Context do
    defstruct [:text, :channel, :channel_type, :user, :my_user_id, :thread_ts]
  end

  @impl true
  def handle_event(
        "message",
        message = %{
          "text" => text,
          "channel" => channel,
          "channel_type" => channel_type,
          "user" => user
        },
        %Slack.Bot{user_id: my_user_id}
      ) do
    # TODO: handle file shares and comments
    handle_message(%Context{
      text: text,
      channel: channel,
      channel_type: channel_type,
      user: user,
      my_user_id: my_user_id,
      thread_ts: message["thread_ts"]
    })
  end

  def handle_event(_type, _payload, _bot) do
    :ok
  end

  # handle message by channel_type
  def handle_message(payload = %Context{channel_type: "im"}) do
    handle_direct_message(payload)
    :ok
  end

  def handle_message(payload = %Context{channel_type: "channel"}) do
    handle_public_message(payload)
    :ok
  end

  defp handle_public_message(ctx) do
    if is_bot?(ctx) do
      show_bot_msg(ctx)
    else
      case Elkarmo.Parser.parse(ctx.text, ctx.my_user_id) do
        :info -> show_karma(ctx)
        :reset -> reset_karma(ctx)
        {:update, changes} -> update_karma(ctx, changes)
        _ -> :ok
      end
    end
  end

  defp handle_direct_message(ctx) do
    if ctx.text == "version" do
      show_version(ctx)
    else
      show_karma(ctx)
    end
  end

  defp show_version(ctx) do
    {:ok, version} = :application.get_key(:elkarmo, :vsn)
    send_msg(ctx, to_string(version))
  end

  defp show_karma(ctx) do
    msg = Elkarmo.Store.get() |> Elkarmo.Formatter.to_message()
    send_msg(ctx, msg)
  end

  defp update_karma(ctx = %Context{user: user}, changes) do
    {cheats, valid_changes} = Enum.split_with(changes, &is_cheater?(user, &1))
    if cheats != [], do: send_msg(ctx, "<@#{user}>: :middle_finger:")
    current_karma = Elkarmo.Store.get()
    new_karma = Elkarmo.Karma.update(current_karma, valid_changes)
    Elkarmo.Store.set(new_karma)

    changed_users = for {user, _} <- changes, do: user
    changed_karmas = Elkarmo.Karma.get(new_karma, changed_users)

    msg = Elkarmo.Formatter.to_message(changed_karmas)

    send_msg(ctx, msg)
  end

  defp reset_karma(ctx) do
    Elkarmo.Store.set(Elkarmo.Karma.empty())
    send_msg(ctx, "Karma is gone :runner::dash:")
  end

  defp is_cheater?(sending_user, {user, karma}), do: sending_user == user and karma > 0

  defp is_bot?(%Context{user: _id}) do
    # TODO
    false
  end

  defp show_bot_msg(ctx = %Context{user: user}) do
    msg = "<@#{user}>: I don't think so :troll:"
    send_msg(ctx, msg)
  end

  defp send_msg(%Context{channel: channel, thread_ts: thread_ts}, message) do
    if thread_ts == nil do
      send_message(channel, message)
    else
      send_message(channel, %{text: message, thread_ts: thread_ts, reply_broadcast: true})
    end
  end
end
