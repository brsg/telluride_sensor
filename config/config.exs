# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# Configure the main viewport for the Scenic application
config :telluride_sensor, :viewport, %{
  name: :main_viewport,
  size: {800, 600},
  default_scene: {TellurideSensor.Scene.Splash, TellurideSensor.Scene.Dashboard},
  drivers: [
    %{
      module: Scenic.Driver.Glfw,
      name: :glfw,
      opts: [resizeable: false, title: "Manufacturing Lines Devices & Sensors"]
    }
  ]
}
