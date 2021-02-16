defmodule SensorSimulator.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    main_viewport_config = Application.get_env(:sensor_simulator, :viewport)

    children = [
      %{
        id: AMQPConnectionManager,
        start: {
          SensorSimulator.Messaging.AMQPConnectionManager,
          :start_link,
          [[
            SensorSimulator.Messaging.SensorEventProducer,
            SensorSimulator.Messaging.SensorHealthConsumer
          ]]
        }
      },
      SensorSimulator.Sensors.SensorRegistry,
      SensorSimulator.Sensors.SensorSupervisor,
      {Scenic.Sensor, nil},
      SensorSimulator.Data.LineConfig,
      {Scenic, viewports: [main_viewport_config]},
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
