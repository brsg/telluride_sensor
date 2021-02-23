defmodule TellurideSensor.Sensors.Sensor do
  @moduledoc """
  Sensor models a single sensor in a hypothetical IoT-style sensor network.

  A Sensor is created and started by calling Sensor.start_link/2 with a
  sensor configuration map having the following elements:
  * `sensor_type` - :pressure, :viscosity, :temperature or other
  * `line_id` - id of the manufacturing line on which the sensor exists
  * `device_id` - id of the device which the sensor is monitoring
  * `sensor_id` - id of the sensor itself
  * `mean` - the mean value to be used to generate random sensor readings using `variance` and a normal distribution
  * `variance` - the variance to be used to generate random sensor readings using `mean` and a normal distribution

  `@emit_interval_ms` determines how often the Sensor will generate a new reading.

  As currently implemented, a Sensor will publish each reading to to event channels:
  * SensorEventProducer - produces the event to a RabbitMQ queue
  * Scenic.Sensor - produces the event to the PubSub topic that the Scenic-based UI is listeing on
  """
  use GenServer, restart: :temporary

  alias TellurideSensor.Messaging.SensorEventProducer
  alias TellurideSensor.Sensors.SensorRegistry

  @emit_interval_ms 50

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(_, sensor_config) do
    GenServer.start_link(__MODULE__, sensor_config, name: via_tuple(sensor_config))
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  def init(sensor_config) do
    line_id = to_string(Keyword.get(sensor_config, :line_id))
    device_id = Keyword.get(sensor_config, :device_id)
    sensor_id = Keyword.get(sensor_config, :sensor_id)
    Scenic.Sensor.register(sensor_id, line_id, device_id)
    Scenic.Sensor.publish(sensor_id, Keyword.get(sensor_config, :mean))

    # emit a sensor reading after @emit_interval_ms
    schedule_emit_task(@emit_interval_ms)

    {:ok, %{config: sensor_config}}
  end

  def handle_info(:emit, %{config: sensor_config}) do

    # compute a new sensor reading
    sensor_reading = read_sensor(sensor_config)

    # publish reading to registered devices
    Scenic.Sensor.publish(sensor_config[:sensor_id], sensor_reading)

    # publish sensor reading message to event queue
    SensorEventProducer.publish(sensor_reading_message(sensor_config, sensor_reading))

    # schedule to emit a sensor after @emit_interval_ms
    schedule_emit_task(@emit_interval_ms)

    {:noreply, %{config: sensor_config}}
  end

  def handle_info({:rmq_update, %{} = update_map}, %{config: sensor_config} = config_map) do
    Scenic.Sensor.publish(sensor_config[:sensor_id], {:update, update_map})
    {:noreply, config_map}
  end

  ################################################################################
  # Private
  ################################################################################

  defp schedule_emit_task(time) do
    Process.send_after(self(), :emit, time)
  end

  defp read_sensor(sensor_config) do
    :rand.normal(sensor_config[:mean], sensor_config[:variance])
  end

  defp sensor_reading_message(sensor_config, reading) do
    %{
      line_id:   sensor_config[:line_id],
      device_id: sensor_config[:device_id],
      sensor_id: sensor_config[:sensor_id],
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      reading:   reading
    }
  end

  def via_tuple(sensor_config) do
    SensorRegistry.via_tuple(
      sensor_config[:line_id],
      sensor_config[:device_id],
      sensor_config[:sensor_id]
    )
  end

end
