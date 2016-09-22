defmodule Elkarmo.Formatter do
  def to_message(map) when map == %{}, do: "There's no karma yet"
  def to_message(map) do
    {nil_karmas, karmas} = Map.to_list(map) |> Enum.partition(&has_nil_karma?/1)
    karmas = Enum.sort(karmas, &compare_karmas/2)
    all_messages = do_to_message(karmas) ++ to_nil_message(nil_karmas)
    Enum.join(all_messages, "\n")
  end

  defp to_nil_message(nil_karmas) do
    for {user, nil} <- nil_karmas, do: "<@#{user}> has no karma"
  end

  defp do_to_message([]), do: []
  defp do_to_message([{user, karma}]), do: [score(user, karma)]
  defp do_to_message([head | tail]) do 
    {_next_user, next_karma} = hd tail
    new_head = case head do
      {_user, karma} when karma > next_karma -> score(head) <> " :+1:"
      _ -> score(head)
    end
    [new_head | do_to_message_many(tail)]
  end

  defp do_to_message_many([{user, karma}]), do: [score(user, karma)]
  defp do_to_message_many([head | tail]) do 
    [score(head) | do_to_message_many(tail)]
  end
  
  defp score({user, karma}), do: score(user, karma)
  defp score(user, karma), do: "<@#{user}>: #{karma}"

  defp compare_karmas({_user1, karma1}, {_user2, karma2}), do: karma1 >= karma2
  defp has_nil_karma?({_user, karma}), do: karma == nil
end