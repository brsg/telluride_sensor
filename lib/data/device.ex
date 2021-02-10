defmodule SensorSimulator.Data.Device do
  @moduledoc """
  The module associated with the struct that defines devices to be
  monitored.
  """
  defstruct [
    mfg_line: nil,
    device: nil,
    sensor_type: nil # :temperature, :viscosity, :pressure
  ]

  def new(%{
    mfg_line: mfg_line,
    device: device,
    sensor_type: sensor_type
  }) do
    %__MODULE__{
      mfg_line: mfg_line,
      device: device,
      sensor_type: sensor_type
    }
  end

  def new(device_list) do
    device_list
    |> Enum.into([], fn %{} = dev_map -> Device.new(dev_map) end)
  end

  def get_id(%__MODULE__{} = device) do
    to_string(device.mfg_line) <> "::" <> device.device
  end
end
