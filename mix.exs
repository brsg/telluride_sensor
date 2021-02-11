defmodule SensorSimulator.MixProject do
  use Mix.Project

  def project do
    [
      app: :sensor_simulator,
      version: "0.1.0",
      elixir: "~> 1.11",
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # mod: {SensorSimulator.Application, []},
      mod: {TellurideDevice, []},
      extra_applications: [:crypto, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      { :amqp, "~> 1.0" },
      {:json, "~> 1.2"},
      {:scenic, "~> 0.10"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:scenic_sensor, "~> 0.7"}
    ]
  end
end
