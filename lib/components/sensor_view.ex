defmodule TellurideSensor.Component.SensorView do
  use Scenic.Component

  alias Scenic.Graph
  alias Scenic.Sensor

  import Scenic.Primitives    #, only: [{:text, 3}, {:rect, 3}]
  import Scenic.Components

  @font_size 14
  @radius 10
  @button_height 35
  @rrect_id_suffix "_rrect"
  @update_id_suffix "_update"

  def verify(reading) when is_bitstring(reading), do: {:ok, reading}
  def verify(_), do: :invalid_data

  def init(reading, opts) do
    # IO.inspect(opts, label: "sensor_view init opts: ")
    width = opts[:styles][:width]
    height = opts[:styles][:height]
    # device_id = opts[:styles][:device_id]
    # sensor_type = opts[:styles][:sensor_type]
    radius = opts[:styles][:radius] || @radius
    fill_color_tuple = fill_color(opts)
    stroke_tuple = stroke_color(opts)
    sensor_id = opts[:id]
    text_id = sensor_id
    update_text_id = update_id(sensor_id)
    rrect_id = rrect_id(sensor_id)

    reading_text =
      case reading == "" do
        true -> ~s|off line|
        false -> ~s|#{reading}|
      end

    update_text = ""

    graph =
      Graph.build(font_size: @font_size, t: {0, @button_height})
      |> group(
        fn g ->
          g
          |> rrect(
            {width, height, radius}, id: rrect_id, stroke: stroke_tuple, fill: fill_color_tuple
          )
          |> text(
            update_text, id: update_text_id, font_size: @font_size,
            fill: :white, t: {width * 0.05, height * 0.60}
          )
          |> text(
            reading_text, id: text_id, font_size: @font_size,
            fill: :white, t: {width * 0.80, height * 0.60}
          )
          |> button("X", width: 20, height: 20, id: {"remove_sensor", sensor_id},
            theme: :danger, t: {width * 0.02, height * 0.15},
            align: :center, font_size: 14
          )
        end
      )
      # |> rrect({width, height, 10}, theme: :primary )
      # |> text(initial_reading, id: text_id, font_size: @font_size, t: {@indent, @font_size * 2})

    # IO.inspect(sensor_id, label: "subscribe to sensor_id: ")
    Sensor.subscribe(sensor_id)

    {:ok, %{graph: graph, viewport: opts[:viewport], opts: opts}, push: graph}
  end

  def handle_info({:sensor, :registered, {_sensor_id, _version, _description}} = _data, graph) do
    # IO.inspect(data, label: "sensor_view handle_info registered: ")
    {:noreply, graph, push: graph}
  end

  def handle_info({:sensor, :unregistered, _sensor_id} = _data, graph) do
    # IO.inspect(data, label: "sensor_view handle_info registered: ")
    {:noreply, graph, push: graph}
  end

  def handle_info({:sensor, :data, {sensor_id, {:update, update_map}, _}} = _data , graph_map) do

    mean_value = Float.round(update_map["mean"], 2)
    min_value = Float.round(update_map["min"])
    max_value = Float.round(update_map["max"])
    update_string = ~s|min: #{min_value}  #{mean_value} max: #{max_value}|
    opts = graph_map[:opts]
    width = opts[:styles][:width]
    height = opts[:styles][:height]
    sensor_state = compute_sensor_state(min_value, mean_value, max_value)
    styles = Keyword.get(opts, :styles)
    styles = Map.put(styles, :sensor_state, sensor_state)
    opts = Keyword.put(opts, :styles, styles)
    graph_map = Map.put(graph_map, :opts, opts)
    stroke_tuple = stroke_color(opts)

    graph = Graph.modify(graph_map[:graph], update_id(sensor_id), &text(&1, update_string))
    graph = Graph.modify(graph, rrect_id(sensor_id),
      &rrect(&1, {width, height, @radius}, stroke: stroke_tuple)
    )
    graph_map = Map.put(graph_map, :graph, graph)

    {:noreply, graph_map, push: graph}
  end

  def handle_info({:sensor, :data, {sensor_id, reading, _}} = _data, graph_map) do
    reading_rounded =
      reading
      |> :erlang.float_to_binary(decimals: 2)

    # si_string = to_string(sensor_id)
    # [_line | [label]] = String.split(si_string, "::")

    graph = Graph.modify(graph_map[:graph], sensor_id, &text(&1, ~s/::  #{reading_rounded}/))
    graph_map = Map.put(graph_map, :graph, graph)

    {:noreply, graph_map, push: graph}
  end

  def rrect_id(sensor_id), do: String.to_atom(to_string(sensor_id) <> @rrect_id_suffix)
  def update_id(sensor_id), do: String.to_atom(to_string(sensor_id) <> @update_id_suffix)

  ## Private / Helping
  defp fill_color(opts) do
    # IO.inspect(opts, label: "fill_color opts: ")
    case opts[:styles][:sensor_type] do
      :pressure -> {:cadet_blue, 255}
      :temperature -> {:cornflower_blue, 255}
      :viscosity -> {:gray, 255}
      _ -> {:white, 128}    ## Unrecognized sensor type
    end
  end

  defp compute_sensor_state(min, mean, max) do
    min_mean_delta = mean - min
    max_mean_delta = max - mean
    delta_delta = abs(max_mean_delta - min_mean_delta)
    delta_pct_mean = delta_delta / mean
    # IO.inspect(delta_pct_mean, label: "\ndelta_pct_mean:\t")

    sensor_state_assign(delta_pct_mean)
  end

  defp sensor_state_assign(value) when value < 0.01, do: :healthy
  defp sensor_state_assign(value) when value >= 0.01 when value < 0.05, do: :warn
  defp sensor_state_assign(value) when value >= 0.05 when value < 0.09, do: :alert
  defp sensor_state_assign(value) when value >= 0.09 when value < 0.5, do: :alarm
  defp sensor_state_assign(value) when value >= 0.5 , do: :dead

  ## stroke colors: lime, yellow, orange, tomato
  defp stroke_color(opts) do
    # IO.inspect(opts, label: "stroke_color opts: ")
    case opts[:styles][:sensor_state] do
      :healthy -> {3, :lime}
      :warn -> {4, :yellow}
      :alert -> {4, :orange}
      :alarm -> {5, :tomato}
      :dead -> {5, :black}
      _ -> {3, :brown}      ## unrecognized state
    end
  end
end
