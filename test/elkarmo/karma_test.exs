defmodule Elkarmo.KarmaTest do
  use ExUnit.Case, async: true
  import Elkarmo.Karma

  @user1 "U1A2B3C4D"
  @user2 "U5A6B7C8D"
  @user3 "U1J28HCKC"

  test "empty" do
    assert empty() == %{}
  end

  test "update empty list" do
    initial_karma = %{@user3 => 3, @user1 => -5}
    assert update(initial_karma, []) == initial_karma
  end

  test "update to empty karma" do
    initial_karma = empty()
    to_apply = [{@user1, -5}, {@user3, 3}]
    assert update(initial_karma, to_apply) == %{@user3 => 3, @user1 => -5}
  end

  test "update to existing karma" do
    initial_karma = %{@user3 => 3, @user1 => -5}
    to_apply = [{@user1, 20}, {@user2, 6}]
    assert update(initial_karma, to_apply) == %{@user3 => 3, @user1 => 15, @user2 => 6}
  end

  test "get nonexistent user" do
    karma = %{@user1 => 50}
    assert get(karma, @user2) == nil
  end

  test "get existing user" do
    karma = %{@user1 => 50, @user2 => -4}
    assert get(karma, @user2) == -4
  end

  test "get multiple users" do
    karma = %{@user1 => 50, @user2 => -4}
    assert get(karma, [@user1, @user2, @user3]) == %{@user1 => 50, @user2 => -4, @user3 => nil}
  end
end
