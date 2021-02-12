defmodule SensorSimulator.Sensors.Sensor do
  use GenServer, restart: :temporary

  alias SensorSimulator.Messaging.SensorEventProducer
  alias SensorSimulator.Sensors.SensorRegistry

  @emit_interval_ms 2_000

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
    Scenic.Sensor.publish(sensor_id, 0.0)

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
