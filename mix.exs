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

  def application do
    [
      # mod: {SensorSimulator.Application, []},
      mod: {TellurideDevice, []},
      extra_applications: [:crypto, :logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:amqp, "~> 1.0" },
      {:json, "~> 1.2"},
      { :uuid, "~> 1.1" },
      {:scenic, "~> 0.10"},
      {:scenic_driver_glfw, "~> 0.10", targets: :host},
      {:scenic_sensor, "~> 0.7"}
    ]
  end
end
