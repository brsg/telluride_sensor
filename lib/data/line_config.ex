defmodule TellurideSensor.Data.LineConfig do
  @moduledoc """
  LineConfig manages the list of devices for a single manufacturing line.
  """
  use GenServer

  alias TellurideSensor.Data.Device

  @max_devices 12

  ## Supervision Tree

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  ## Client API

  @doc """
  mfg_line should be formatted as an atom: `:line_number`.
  """

  def add_pressure_device(mfg_line) when is_atom(mfg_line) do
    GenServer.call(__MODULE__, {:add_device, mfg_line, :pressure})
  end

  def add_temperature_device(mfg_line) when is_atom(mfg_line) do
    GenServer.call(__MODULE__, {:add_device, mfg_line, :temperature})
  end

  def add_viscosity_device(mfg_line) when is_atom(mfg_line) do
    GenServer.call(__MODULE__, {:add_device, mfg_line, :viscosity})
  end

  def fetch_device_list(mfg_line) when is_atom(mfg_line) do
    GenServer.call(__MODULE__, {:find, mfg_line})
  end

  def remove_device(sensor_id) when is_atom(sensor_id) do
    GenServer.cast(__MODULE__, {:remove, sensor_id})
  end

  ## Server callbacks

  def init(_args) do
    config_map = %{line_one: [], line_two: [], line_three: []}
    {:ok, config_map}
  end

  def handle_call({:find, line_key}, _, config_map) do
    device_list =
      Map.get(config_map, line_key)
      |> Enum.sort_by(&(&1.device))
      # |> Enum.sort(fn %Device{} = device -> asc(device.device) end)
    {:reply, device_list, config_map}
  end

  def handle_call({:add_device, line_key, sensor_type}, _, config_map) do
    {result, map} = add_device(line_key, sensor_type, config_map)
    {:reply, result, map}
  end

  def handle_cast({:remove, sensor_id}, config_map) do
    device_id = device_id_from_sensor_id(sensor_id)

    config_map_prime =
      config_map
      |> remove_if_found(device_id, :line_one)
      |> remove_if_found(device_id, :line_two)
      |> remove_if_found(device_id, :line_three)

    {:noreply, config_map_prime}
  end

  ## Helping
  defp remove_if_found(%{} = config_map, device_id, key) do
    list_prime =
      Map.get(config_map, key)
      |> Enum.reject(fn %Device{} = device -> device.device == device_id end)

    Map.put(config_map, key, list_prime)
  end

  defp device_id_from_sensor_id(sensor_id) when is_atom(sensor_id) do
    sensor_id |> to_string() |> String.split("::") |> List.last()
  end

  defp add_device(line_key, sensor_type, config_map) do
    device_list = Map.get(config_map, line_key)
    list_size = Enum.count(device_list)
    # IO.inspect(list_size, label: "list_size: ")
    case  list_size < @max_devices do
      true ->
        next_device = compose_next_device(line_key, device_list, sensor_type)
        device_list_prime = [next_device | device_list ] |> Enum.reverse()
        config_map_prime = Map.put(config_map, line_key, device_list_prime)
        {{:ok, next_device}, config_map_prime}
      false ->
        {{:max_devices, nil}, config_map}
    end
  end

  defp compose_next_device(line_id, device_list, sensor_type) do
    count = Enum.count(device_list) + 1
    line = to_string(line_id)
    device =
      case count < 10 do
        true ->
          ~s|#{line}_device_0#{count}|
        false ->
          ~s|#{line}_device_#{count}|
      end
    device_map = %{mfg_line: line_id, device: device, sensor_type: sensor_type}
    Device.new(device_map)
  end

end
