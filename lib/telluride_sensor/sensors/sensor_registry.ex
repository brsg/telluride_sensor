defmodule TellurideSensor.Sensors.SensorRegistry do
  @moduledoc """
  SensorRegistry is a local registry for Sensor genservers.
  """

  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple(line_id, device_id, sensor_id) do
    {:via, Registry, {__MODULE__, registry_id(line_id, device_id, sensor_id)}}
  end

  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end

  def registry_id(line_id, device_id, sensor_id) do
    "#{line_id}-#{device_id}-#{sensor_id}"
  end

end
