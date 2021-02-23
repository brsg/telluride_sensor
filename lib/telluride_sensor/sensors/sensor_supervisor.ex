defmodule TellurideSensor.Sensors.SensorSupervisor do
  @moduledoc """
  SensorSupervisor is responsible for managing a collection of Sensors.
  """
  use DynamicSupervisor

  alias TellurideSensor.Sensors.Sensor

  ################################################################################
  # Client interface
  ################################################################################

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_sensor(sensor_type, line_id, device_id, sensor_id, mean, variance) do
    child_spec = {Sensor, [sensor_type: sensor_type, line_id: line_id, device_id: device_id, sensor_id: sensor_id, mean: mean, variance: variance]}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_sensor(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  def list_sensors do
    DynamicSupervisor.which_children(__MODULE__)
  end

  ################################################################################
  # Server callbacks
  ################################################################################

  @impl true
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
