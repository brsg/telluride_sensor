defmodule TellurideSensor.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    main_viewport_config = Application.get_env(:telluride_sensor, :viewport)

    children = [
      %{
        id: AMQPConnectionManager,
        start: {
          TellurideSensor.Messaging.AMQPConnectionManager,
          :start_link,
          [[
            TellurideSensor.Messaging.SensorEventProducer,
            TellurideSensor.Messaging.SensorHealthConsumer
          ]]
        }
      },
      TellurideSensor.Sensors.SensorRegistry,
      TellurideSensor.Sensors.SensorSupervisor,
      {Scenic.Sensor, nil},
      TellurideSensor.Data.LineConfig,
      {Scenic, viewports: [main_viewport_config]},
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
