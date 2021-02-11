defmodule SensorSimulator.Component.SensorView do
  use Scenic.Component

  alias Scenic.Graph
  alias Scenic.Sensor

  import Scenic.Primitives    #, only: [{:text, 3}, {:rect, 3}]

  @font_size 20
  @radius 10
  @button_height 35


  def verify(reading) when is_bitstring(reading), do: {:ok, reading}
  def verify(_), do: :invalid_data

  def init(reading, opts) do
    IO.inspect(opts, label: "sensor_view init opts: ")
    width = opts[:styles][:width]
    height = opts[:styles][:height]
    device_id = opts[:styles][:device_id]
    sensor_type = opts[:styles][:sensor_type]
    radius = opts[:styles][:radius] || @radius
    fill_color_tuple = fill_color(opts)
    stroke_tuple = stroke_color(opts)
    sensor_id = opts[:id]
    text_id = sensor_id

    initial_reading =
      case reading == "" do
        true -> ~s|#{device_id}: off line|
        false -> ~s|#{device_id}: #{reading}|
      end

    graph =
      Graph.build(font_size: @font_size, t: {0, @button_height})
      |> group(
        fn g ->
          g
          |> rrect(
            {width, height, radius}, stroke: stroke_tuple, fill: fill_color_tuple
          )
          |> text(
            initial_reading, id: text_id, font_size: @font_size,
            fill: :white, t: {width * 0.05, height * 0.75}
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

  def handle_info({:sensor, :data, {sensor_id, reading, _}} = data, graph_map) do
    reading_rounded =
      reading
      |> :erlang.float_to_binary(decimals: 2)

    si_string = to_string(sensor_id)
    [_line | [label]] = String.split(si_string, "::")

    graph = Graph.modify(graph_map[:graph], sensor_id, &text(&1, ~s|#{label}: #{reading_rounded}|))
    graph_map = Map.put(graph_map, :graph, graph)

    {:noreply, graph_map, push: graph}
  end

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
