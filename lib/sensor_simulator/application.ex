defmodule SensorSimulator.Application do
  @moduledoc false

  # use Application

  def start(_type, _args) do
    IO.puts("\SensorSimulator.Application start\n")
    main_viewport_config = Application.get_env(:sensor_simulator, :viwport)

    children = [
      SensorSimulator.Messaging.AMQPConnectionManager,
      SensorSimulator.Sensors.SensorRegistry,
      SensorSimulator.Sensors.SensorSupervisor,
      {Scenic.Sensor, nil},
      SensorSimulator.Data.LineConfig,
      {Scenic, viewports: [main_viewport_config]}
    ]
    # opts = [strategy: :one_for_one, name: SensorSimulator.Supervisor]
    # Supervisor.start_link(children, opts)
    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
