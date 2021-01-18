defmodule SensorSimulator.MixProject do
  use Mix.Project

  def project do
    [
      app: :sensor_simulator,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      { :amqp, "~> 1.0" },
      {:json, "~> 1.2"},
    ]
  end
end
