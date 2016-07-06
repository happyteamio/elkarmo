defmodule Elkarmo.Karma do
  def empty(), do: %{}

  def update(karma, []), do: karma

  def update(karma, changes) do
    changes |> Enum.reduce(karma, &do_update/2)
  end

  def get(karma, list) when is_list(list) do
    users_with_karma = for user <- list, do: {user, get(karma, user)} 
    users_with_karma |> Enum.into(%{})
  end

  def get(karma, user), do: Map.get(karma, user)

  defp do_update({user, karma_to_add}, existing_karma) do
    Map.update existing_karma, user, karma_to_add, &(&1 + karma_to_add)
  end
end
