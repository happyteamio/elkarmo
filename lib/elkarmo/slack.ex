defmodule Elkarmo.Slack do
  use Slack

  defmodule Context do
    defstruct [:text, :user, :channel, :slack, :thread_id]
  end

  def handle_connect(slack, state) do
    IO.puts("Connected as #{slack.me.name}")
    {:ok, state}
  end

  def handle_event(_message = %{type: "message", reply_to: _}, _slack, state), do: {:ok, state}

  def handle_event(message = %{type: "message"}, slack, state) do
    text_user =
      case message do
        %{subtype: "file_comment", comment: comment} ->
          {comment[:comment], comment[:user]}

        %{subtype: "file_share", file: %{initial_comment: comment}} ->
          {comment[:comment], comment[:user]}

        %{subtype: _subtype} ->
          nil

        _msg ->
          {message.text, message.user}
      end

    if text_user != nil do
      {text, user} = text_user

      ctx = %Context{
        text: text,
        user: user,
        channel: message.channel,
        slack: slack,
        thread_id: message[:thread_ts]
      }

      handle_message(ctx)
    end

    {:ok, state}
  end

  def handle_event(_message, _slack, state), do: {:ok, state}

  defp handle_message(context) do
    if is_direct_message?(context) do
      handle_direct_message(context)
    else
      handle_public_message(context)
    end
  end

  defp handle_public_message(context) do
    if is_bot?(context) do
      show_bot_msg(context)
    else
      case Elkarmo.Parser.parse(context.text, context.slack.me.id) do
        :info -> show_karma(context)
        :reset -> reset_karma(context)
        {:update, changes} -> update_karma(context, changes)
        _ -> :ok
      end
    end
  end

  defp handle_direct_message(context) do
    if context.text == "version" do
      show_version(context)
    else
      show_karma(context)
    end
  end

  defp is_bot?(%Context{slack: slack, user: id}) do
    get_in(slack.users, [id, :is_bot]) == true
  end

  defp is_direct_message?(%Context{channel: channel, slack: slack}),
    do: Map.has_key?(slack.ims, channel)

  defp show_version(ctx) do
    {:ok, version} = :application.get_key(:elkarmo, :vsn)
    send_message(to_string(version), ctx)
  end

  defp show_bot_msg(ctx = %Context{user: user}) do
    msg = "<@#{user}>: I don't think so :troll:"
    send_message(msg, ctx)
  end

  defp show_karma(ctx) do
    msg = Elkarmo.Store.get() |> Elkarmo.Formatter.to_message()
    send_message(msg, ctx)
  end

  defp reset_karma(ctx) do
    Elkarmo.Store.set(Elkarmo.Karma.empty())
    send_message("Karma is gone :runner::dash:", ctx)
  end

  defp update_karma(ctx = %Context{user: user}, changes) do
    {cheats, valid_changes} = Enum.split_with(changes, &is_cheater?(user, &1))
    if cheats != [], do: send_message("<@#{user}>: :middle_finger:", ctx)
    current_karma = Elkarmo.Store.get()
    new_karma = Elkarmo.Karma.update(current_karma, valid_changes)
    Elkarmo.Store.set(new_karma)

    changed_users = for {user, _} <- changes, do: user
    changed_karmas = Elkarmo.Karma.get(new_karma, changed_users)

    msg = Elkarmo.Formatter.to_message(changed_karmas)
    send_message(msg, ctx)
  end

  defp is_cheater?(sending_user, {user, karma}), do: sending_user == user and karma > 0

  defp send_message(msg, %Context{channel: channel, slack: slack, thread_id: thread_id}) do
    if thread_id == nil do
      send_message(msg, channel, slack)
    else
      %{type: "message", text: msg, channel: channel, thread_ts: thread_id, reply_broadcast: true}
      |> Poison.encode!()
      |> send_raw(slack)
    end
  end
end
