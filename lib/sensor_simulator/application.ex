defmodule SensorSimulator.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    IO.puts("\SensorSimulator.Application start\n")
    children = [
      {SensorSimulator.Messaging.AMQPConnectionManager, []},
      {SensorSimulator.Sensors.TemperatureSensor, %{device_id: "AAA", sensor_id: 1001, mean: 250.0, variance: 25.0}}
    ]
    opts = [strategy: :one_for_one, name: SensorSimulator.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
