defmodule TellurideDevice do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    # load the viewport configuration from config
    main_viewport_config = Application.get_env(:sensor_simulator, :viewport)

    # start the application with the viewport
    children = [
      SensorSimulator.Messaging.AMQPConnectionManager,
      SensorSimulator.Sensors.SensorRegistry,
      SensorSimulator.Sensors.SensorSupervisor,
      {Scenic.Sensor, nil},
      SensorSimulator.Data.LineConfig,
      {Scenic, viewports: [main_viewport_config]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
