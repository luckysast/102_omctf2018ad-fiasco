defmodule FiascoTest do
  use ExUnit.Case
  doctest Fiasco

  test "greets the world" do
    assert Fiasco.hello() == :world
  end
end
