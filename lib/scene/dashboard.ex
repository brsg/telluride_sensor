defmodule TellurideSensor.Scene.Dashboard do
  @moduledoc """
  Dashboard configures and manages a [Scenic](https://github.com/boydm/scenic)-based
  UI for visualizing the "sensor network" used in this example.
  """
  use Scenic.Scene

  require Logger

  alias Scenic.{Graph, ViewPort}
  alias Scenic.Component.Button
  import Scenic.Primitives
  import Scenic.Components
  alias Scenic.Sensor

  alias TellurideSensor.Component.SensorView
  alias TellurideSensor.Data.LineConfig
  alias TellurideSensor.Data.Device
  alias TellurideSensor.Sensors.SensorSupervisor

  @telluride_image :code.priv_dir(:telluride_sensor)
    |> Path.join("/static/images/brsgMtnOnlyThin-Clear_telluride_171_by_90.png")
  @telluride_hash Scenic.Cache.Support.Hash.file!(@telluride_image, :sha)
  @title "A Polyglot Demo of Pure Elixir"
  @sub_title "Glass to Analytics"
  @header_height 90
  @alley_width 30
  @button_height 30
  @indent 15
  @row_height @button_height
  @col 3
  @num_sensor_types 3

  def init(_data, _opts) do
    # IO.inspect(opts, label: "opts: ")

    Scenic.Cache.Static.Texture.load(@telluride_image, @telluride_hash)
      graph =
        Graph.build(font: :roboto, font_size: 16, theme: :light)
        |> rect(
          {171, 90}, id: :telluride_image, fill: {:image, {@telluride_hash, 255}},
          t: {0, 0}
        )
        |> text(@title, font_size: 36, fill: :dark_blue, font_blur: 3, t: {193, 38})
        |> text(@title, font_size: 36, fill: :dark_blue, t: {190, 35})
        |> text(@sub_title, font_size: 28, fill: :dark_blue, t: {190, 66})
        |> build_column(0, LineConfig.fetch_device_list(:line_one))
        |> build_column(1, LineConfig.fetch_device_list(:line_two))
        |> build_column(2, LineConfig.fetch_device_list(:line_three))

    {:ok, graph, push: graph}
  end

  def filter_event({:click, "add_pressure_0"} = event, _, graph) do
    add_pressure_device(:line_one)
    build_and_push_graph(event, graph)
  end

  def filter_event({:click, "add_pressure_1"} = event, _, graph) do
    add_pressure_device(:line_two)
    build_and_push_graph(event, graph)
  end

  def filter_event({:click, "add_pressure_2"} = event, _, graph) do
    add_pressure_device(:line_three)
    build_and_push_graph(event, graph)
  end

  def filter_event({:click, "add_temperature_0"} = event, _, graph) do
    add_temperature_device(:line_one)
    build_and_push_graph(event, graph)
  end

  def filter_event({:click, "add_temperature_1"} = event, _, graph) do
    add_temperature_device(:line_two)
    build_and_push_graph(event, graph)
  end

  def filter_event({:click, "add_temperature_2"} = event, _, graph) do
    add_temperature_device(:line_three)
    build_and_push_graph(event, graph)
  end

  def filter_event({:click, "add_viscosity_0"} = event, _, graph) do
    add_viscosity_device(:line_one)
    build_and_push_graph(event, graph)
  end

  def filter_event({:click, "add_viscosity_1"} = event, _, graph) do
    add_viscosity_device(:line_two)
    build_and_push_graph(event, graph)
  end

  def filter_event({:click, "add_viscosity_2"} = event, _, graph) do
    add_viscosity_device(:line_three)
    build_and_push_graph(event, graph)
  end

  def filter_event({:click, {"remove_sensor", sensor_id}} = event, _, graph) do
    case fetch_sensor(sensor_id) do
      nil ->
        Logger.error("sensor #{inspect sensor_id} already removed")
      {sensor_id, _line_id, _device_id, pid} = _sensor ->
        SensorSupervisor.stop_sensor(pid)
        LineConfig.remove_device(sensor_id)
        Logger.info("Removed sensor identified by #{inspect sensor_id}")
    end
    build_and_push_graph(event, graph)
  end

  def handle_info({:sensor, :registered, {_sensor_id, _version, _description}} = _data, graph) do
    # IO.inspect(data, label: "dashboard handle_info registered: ")
    {:noreply, graph, push: graph}
  end

  def handle_info({:sensor, :data, {_sensor_id, _reading, _}} = _data, graph) do
    # IO.inspect(data, label: "dashboard handle_info data: ")
    # reading_rounded =
      # reading
      # |> :erlang.float_to_binary(decimals: 2)
    # graph = Graph.modify(graph, sensor_id, &text(&1, reading_rounded))
    {:noreply, graph, push: graph}
  end

  defp build_and_push_graph(event, graph) do
    graph_temp =
      graph
      |> Graph.reduce(
        graph, fn primitive, accum_graph ->
          primitive_id = Map.get(primitive, :id)
          if String.contains?(to_string(primitive_id), "col_") do
            Graph.delete(accum_graph, primitive_id)
          else
            accum_graph
          end
      end)
      |> build_column(0, LineConfig.fetch_device_list(:line_one))
      |> build_column(1, LineConfig.fetch_device_list(:line_two))
      |> build_column(2, LineConfig.fetch_device_list(:line_three))

    {:cont, event, graph_temp, push: graph_temp}
  end

  defp add_pressure_device(mfg_line) do
    case LineConfig.add_pressure_device(mfg_line) do
      {:ok, %Device{} = next} ->
        SensorSupervisor.start_sensor(next.sensor_type, mfg_line, next.device, Device.get_id(next), random_mean(), random_variance())
        # |> IO.inspect(label: "start_sensor pressure: ")
        Logger.info("New pressure device for line one, #{inspect next}.")
      {:max_devices, _} -> Logger.warn("Max devices reached for line one")
    end
    :ok
  end

  defp add_temperature_device(mfg_line) do
    case LineConfig.add_temperature_device(mfg_line) do
      {:ok, %Device{} = next} ->
        SensorSupervisor.start_sensor(next.sensor_type, mfg_line, next.device, Device.get_id(next), random_mean(), random_variance())
        # |> IO.inspect(label: "start_sensor temperature: ")
        Logger.info("New temperature device for line one, #{inspect next}.")
      {:max_devices, _} -> Logger.warn("Max devices reached for line one")
    end
    :ok
  end

  defp add_viscosity_device(mfg_line) do
    case LineConfig.add_viscosity_device(mfg_line) do
      {:ok, %Device{} = next} ->
        SensorSupervisor.start_sensor(next.sensor_type, mfg_line, next.device, Device.get_id(next), random_mean(), random_variance())
        # |> IO.inspect(label: "start_sensor viscosity: ")
        Logger.info("New viscosity device for line one, #{inspect next}.")
      {:max_devices, _} -> Logger.warn("Max devices reached for line one")
    end
    :ok
  end

  defp viewport_dimensions() do
      viewport = Application.fetch_env!(:telluride_sensor, :viewport)
      # IO.inspect(viewport, label: "viewport: ")
      Map.get(viewport, :size)
  end

  defp column_width() do
    {vp_width, _} = viewport_dimensions()
    Float.round(vp_width / (@col + 0.5) - @indent / (@col + 0.5), 2)
  end

  defp rect_height() do
    @row_height - Float.round(@indent / 12)
  end

  defp rect_width() do
    col_width = column_width()
    col_width ##- Float.round(@indent / (@num_sensor_types * 0.5), 2)
  end

  defp button_width() do
    col_width = column_width()
    Float.round(col_width / @num_sensor_types - @indent / @num_sensor_types, 2)
  end

  # defp build_graph() do
  # end

  defp build_column(graph, col_num, device_list) do
    col_id = ~s|col_#{col_num}|
    column_label = ~s|Mfg. Line #{inspect col_num + 1}|
    x_offset = col_num * column_width()
    alley = alley_value(col_num)
    button_width = button_width()
    ##
    ## col_num zero represents mfg line 1, etc.
    ##
    temp_id = ~s|add_temperature_#{col_num}|
    viscosity_id = ~s|add_viscosity_#{col_num}|
    pressure_id = ~s|add_pressure_#{col_num}|

    graph
      |> group(
        fn g ->
          g
          |> text(column_label, font_size: 24, fill: :dark_blue,
                  t: {@indent + (column_width() * 0.30), @button_height * 0.65}
          )
          |> button("Temp. +", width: button_width, height: @button_height,
                    id: temp_id, theme: :primary,
                    t: {@indent, @button_height}, align: :center
          )
          |> button("Visc. +", width: button_width, height: @button_height,
                    id: viscosity_id, theme: :secondary,
                    t: {@indent * 1.5 + button_width, @button_height}, align: :center
          )
          |> button("Press. +", width: button_width, height: @button_height,
                    id: pressure_id, theme: :info,
                    t: {(@indent + button_width) * 2, @button_height}, align: :center
          )
          |> build_sensors(device_list)
        end,
        id: col_id,
        t: {x_offset + alley, @header_height}
      )
  end

  defp alley_value(col_num), do: col_num * @alley_width
  # defp alley_value(_), do: @alley_width

  defp build_sensors(group, device_list) do
    group_prime =
      case Enum.count(device_list) > 0 do
        true ->
          group_prime =
            device_list
            |> Enum.with_index()
            |> add_to_group(group)
          group_prime
        false -> group
      end
    group_prime
  end

  defp add_to_group(indexed_device_list, group) do
    indexed_device_list
    |> Enum.reduce(group, fn {%Device{} = device, index}, accum_group ->
      SensorView.add_to_graph(
        accum_group, "", t: {@indent, (index + 1) * @row_height},
        align: :center, id: Device.get_id(device),
        width: rect_width(), height: rect_height(), device_id: device.device,
        sensor_type: device.sensor_type, sensor_state: :healthy
      )
    end)
  end

  defp random_mean() do
    Enum.random(88..333) / 1
  end

  defp random_variance() do
    Enum.random(1..13) / 1
  end

  defp fetch_sensor(sensor_id_wanted) when is_atom(sensor_id_wanted) do
    Scenic.Sensor.list()
    |> Enum.filter(fn {sensor_id, _line_id, _device_id, _pid} ->
      sensor_id == sensor_id_wanted
    end)
    |> List.first()
  end

end
