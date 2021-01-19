defmodule SensorSimulator.Sensors.TemperatureSensor do
  use GenServer

  @emit_interval_ms 2_000

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(args \\ []) do
    IO.puts("TemperatureSensor.start_link with args #{inspect args}")
    GenServer.start_link(__MODULE__, args, [name: __MODULE__])
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  def init(sensor_config) do
    IO.puts("TemperatureSenstor.init called with sensor_config #{inspect sensor_config}")
    # seed the random number generator
    << i1 :: unsigned-integer-32, i2 :: unsigned-integer-32, i3 :: unsigned-integer-32>> = :crypto.strong_rand_bytes(12)
    :rand.seed(:exsplus, {i1, i2, i3})

    mean = sensor_config[:mean]
    IO.puts("mean = #{mean}")

    # st up to emit a sensor reading every @emit_interval_ms
    timer = Process.send_after(self(), {:emit, sensor_config[:mean]}, @emit_interval_ms)

    {:ok, %{config: sensor_config, timer: timer}}
  end

  def handle_info({:emit, last} = message, %{config: sensor_config, timer: timer} = state) do
    IO.puts("handle_info called with message #{inspect message} and state #{inspect state}")
    Process.cancel_timer(timer)

    # emit
    current = :rand.normal(sensor_config[:mean], sensor_config[:variance])
    IO.puts("config=#{inspect sensor_config}, last=#{last}, current=#{current}")

    new_timer = Process.send_after(self(), {:emit, current}, @emit_interval_ms)
    {:noreply, %{config: sensor_config, timer: new_timer}}
  end

end
