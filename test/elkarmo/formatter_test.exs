defmodule Elkarmo.FormatterTest do
  use ExUnit.Case, async: true
  import Elkarmo.Formatter

  @user1 "U1A2B3C4D"
  @user2 "U5A6B7C8D"
  @user3 "U1J28HCKC"
  @user4 "U1Q2W3E4R"

  test "empty karma" do
    assert to_message(%{}) == "There's no karma yet"
  end

  test "single user" do
    karma = %{@user1 => 15}
    assert to_message(karma) == "<@#{@user1}>: 15"
  end

  test "single with nil karma" do
    karma = %{@user1 => nil}
    assert to_message(karma) == "<@#{@user1}> has no karma"
  end

  test "mulitple users" do
    karma = %{@user1 => 0, @user3 => -100, @user2 => 90, @user4 => nil}
    assert to_message(karma) <> "\n" == """
    <@#{@user2}>: 90 :+1:
    <@#{@user1}>: 0
    <@#{@user3}>: -100
    <@#{@user4}> has no karma
    """
  end

  test "don't append winner icon when there's a draw between only users" do
    karma = %{@user1 => 90, @user2 => 90}
    assert to_message(karma) <> "\n" == """
    <@#{@user1}>: 90
    <@#{@user2}>: 90
    """
  end

  test "don't append winner icon when there's a draw" do
    karma = %{@user1 => 90, @user2 => 10, @user3 => 90}
    assert to_message(karma) <> "\n" == """
    <@#{@user1}>: 90
    <@#{@user3}>: 90
    <@#{@user2}>: 10
    """
  end
end
