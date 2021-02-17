defmodule SensorSimulator.Component.SensorView do
  use Scenic.Component

  alias Scenic.Graph
  alias Scenic.Sensor

  import Scenic.Primitives    #, only: [{:text, 3}, {:rect, 3}]

  @font_size 14
  @radius 10
  @button_height 35
  @rrect_id_suffix "_rrect"
  @update_id_suffix "_update"

  def verify(reading) when is_bitstring(reading), do: {:ok, reading}
  def verify(_), do: :invalid_data

  def init(reading, opts) do
    IO.inspect(opts, label: "sensor_view init opts: ")
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
        end
      )
      # |> rrect({width, height, 10}, theme: :primary )
      # |> text(initial_reading, id: text_id, font_size: @font_size, t: {@indent, @font_size * 2})

    IO.inspect(sensor_id, label: "subscribe to sensor_id: ")
    Sensor.subscribe(sensor_id)

    {:ok, %{graph: graph, viewport: opts[:viewport]}, push: graph}
  end

  def handle_info({:sensor, :registered, {_sensor_id, _version, _description}} = data, graph) do
    IO.inspect(data, label: "sensor_view handle_info registered: ")
    {:noreply, graph, push: graph}
  end

  def handle_info({:sensor, :data, {sensor_id, {:update, update_map}, _}} = data , graph_map) do
    IO.inspect(sensor_id, label: "\nsensor_id:\t")
    IO.inspect(update_map, label: "\nupdate_map:\t")
    IO.inspect(data, label: "\nsensor_view.handle_info data:\t")
    IO.inspect(graph_map, label: "\nsensor_view.handle_info graph_map:\t")

    mean_value = Float.round(update_map["mean"], 2)
    update_string = ~s|mean #{mean_value}|

    graph = Graph.modify(graph_map[:graph], update_id(sensor_id), &text(&1, update_string))
    graph_map = Map.put(graph_map, :graph, graph)

    {:noreply, graph_map, push: graph}
  end

  def handle_info({:sensor, :data, {sensor_id, reading, _}} = _data, graph_map) do
    reading_rounded =
      reading
      |> :erlang.float_to_binary(decimals: 2)

    # si_string = to_string(sensor_id)
    # [_line | [label]] = String.split(si_string, "::")
    label = "R"

    graph = Graph.modify(graph_map[:graph], sensor_id, &text(&1, ~s|#{label}: #{reading_rounded}|))
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

  ## stroke colors: lime, yellow, orange, tomato
  defp stroke_color(opts) do
    # IO.inspect(opts, label: "stroke_color opts: ")
    case opts[:styles][:sensor_state] do
      :healthy -> {3, :lime}
      :warn -> {3, :yellow}
      :alert -> {3, :orange}
      :alarm -> {3, :tomato}
      :dead -> {3, :black}
      _ -> {3, :brown}      ## unrecognized state
    end
  end
end
