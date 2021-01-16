defmodule SensorSimulatorTest do
  use ExUnit.Case
  doctest SensorSimulator

  test "greets the world" do
    assert SensorSimulator.hello() == :world
  end
end
