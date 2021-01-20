defmodule SensorSimulator.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    IO.puts("\SensorSimulator.Application start\n")
    children = [
      {SensorSimulator.Messaging.AMQPConnectionManager, []},
      {SensorSimulator.Sensors.SensorSupervisor, []}
    ]
    opts = [strategy: :one_for_one, name: SensorSimulator.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
