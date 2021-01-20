defmodule SensorSimulator.Sensors.SensorSupervisor do
  # Automatically defines child_spec/1
  use DynamicSupervisor

  alias SensorSimulator.Sensors.TemperatureSensor

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(device_id, sensor_id, mean, variance) do
    spec = {TemperatureSensor, device_id: device_id, sensor_id: sensor_id, mean: mean, variance: variance}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def stop_child(pid) do
    Supervisor.terminate_child(__MODULE__, pid)
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  @impl true
  @spec init(any) ::
          {:ok,
           %{
             extra_arguments: [any],
             intensity: non_neg_integer,
             max_children: :infinity | non_neg_integer,
             period: pos_integer,
             strategy: :one_for_one
           }}
  def init(init_arg) do
    # seed the random number generator used by the sensors
    << i1 :: unsigned-integer-32, i2 :: unsigned-integer-32, i3 :: unsigned-integer-32>> = :crypto.strong_rand_bytes(12)
    :rand.seed(:exsplus, {i1, i2, i3})

    DynamicSupervisor.init(
      strategy: :one_for_one,
      extra_arguments: [init_arg]
    )
  end

end
