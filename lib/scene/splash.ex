defmodule SensorSimulator.Scene.Splash do
  @moduledoc """
  BRSG Ideas That Scale splash page, transition to landing page.
  """

  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [{:rect, 3}, {:update_opts, 2}]

  @brsg_path :code.priv_dir(:sensor_simulator)
    |> Path.join("/static/images/ideas_that_scale_600_by_173.png")
  @brsg_hash Scenic.Cache.Support.Hash.file!(@brsg_path, :sha)

  @brsg_width 600
  @brsg_height 173

  @graph Graph.build()
    |> rect(
      {@brsg_width, @brsg_height},
      id: :brsg,
      fill: {:image, {@brsg_hash, 0}}
    )

  @animate_ms 30
  @finish_delay_ms 1_000

  def init(first_scene, opts) do
    viewport = opts[:viewport]

    # calculate the transform that centers the brsg logo in the viewport
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    position = {
      vp_width / 2 - @brsg_width / 2,
      vp_height / 2 - @brsg_height / 2
    }

    # load the brsg logo texture into the cache
    Scenic.Cache.Static.Texture.load(@brsg_path, @brsg_hash)
    # |> IO.inspect(label: "texture_load: ")

    # move the brsg logo into the correct location
    graph = Graph.modify(@graph, :brsg, &update_opts(&1, t: position))

    # start a simple time
    {:ok, timer} = :timer.send_interval(@animate_ms, :animate)

    state = %{
      viewport: viewport,
      timer: timer,
      graph: graph,
      first_scene: first_scene,
      alpha: 0
    }

    {:ok, state, push: graph}
  end

  @doc """
  An animation to saturate the image according to a timer that
  increments and whose value is applied to the alpha channel of
  the BRSG logo.

  When fully saturated, transition to the landing scene.
  """
  def handle_info(
      :animate,
      %{timer: timer, alpha: a} = state
    )
    when a >= 256 do
    # IO.puts("\nhandle_info :animate 1\n")
    :timer.cancel(timer)
    Process.send_after(self(), :finish, @finish_delay_ms)
    {:noreply, state}
  end

  def handle_info(:finish, state) do
    # IO.puts("\nhandle_info :finish 2\n")
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_info(:animate, %{alpha: alpha, graph: graph} = state) do
    # IO.puts("\nhandle_info :animate 3 with brsg_hash #{inspect @brsg_hash} alpha #{inspect alpha} BEGIN\n")
    graph =
      Graph.modify(
        graph,
        :brsg,
        &update_opts(&1, fill: {:image, {@brsg_hash, alpha}})
      )

    # IO.puts("\nhandle_info :animate 3 with brsg_hash #{inspect @brsg_hash} alpha #{inspect alpha} END\n")
    {:noreply, %{state | graph: graph, alpha: alpha + 2}, push: graph}
  end

  @doc """
  Interrupt animation and go directly to landing scene.
  """
  def handle_input({:cursor_button, {_, :press, _, _}}, _context, state) do
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_input({:key, _}, _context, state) do
    go_to_first_scene(state)
    {:noreply, state}
  end

  def handle_input(_input, _context, state), do: {:noreply, state}

  ## Helping
  defp go_to_first_scene(%{viewport: vp, first_scene: first_scene}) do
    # IO.puts("go_to_first_scene #{first_scene}")
    ViewPort.set_root(vp, {first_scene, nil})
  end
end
