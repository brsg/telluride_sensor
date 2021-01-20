defmodule SensorSimulator.Sensors.TemperatureSensor do
  use GenServer

  alias SensorSimulator.Messaging.SensorEventProducer

  @emit_interval_ms 2_000

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(module, init_arg, options \\ []) do
    IO.puts("TemperatureSensor.start_link called with module #{inspect module}, init_arg #{inspect init_arg} and options #{inspect options}")
    GenServer.start_link(__MODULE__, init_arg, [name: __MODULE__])
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  def init(sensor_config) do

    # schedule to emit a sensor after @emit_interval_ms
    schedule_emit_task(@emit_interval_ms)

    {:ok, %{config: sensor_config}}
  end

  def handle_info(:emit, %{config: sensor_config}) do

    # compute a new sensor reading
    sensor_reading = :rand.normal(sensor_config[:mean], sensor_config[:variance])

    # build sensor reading message
    message = sensor_reading_message(sensor_config, sensor_reading)

    # emit sensor reading message
    SensorEventProducer.publish(message)

    # schedule to emit a sensor after @emit_interval_ms
    schedule_emit_task(@emit_interval_ms)

    {:noreply, %{config: sensor_config}}
  end

  ################################################################################
  # Private
  ################################################################################

  def schedule_emit_task(time) do
    Process.send_after(self(), :emit, time)
  end

  def sensor_reading_message(sensor_config, reading) do
    %{
      device_id: sensor_config[:device_id],
      sensor_id: sensor_config[:sensor_id],
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      reading: reading
    }
  end

end
