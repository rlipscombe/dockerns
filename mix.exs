defmodule Dockerns.MixProject do
  use Mix.Project

  def project do
    [
      app: :dockerns,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      default_task: "escript.build",
      escript: [main_module: Dockerns.Main],
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
      {:dns, "~> 2.1"},   # BSD 3-clause
      {:gun, "~> 1.3"},   # ISC
      {:jason, "~> 1.1"}  # Apache 2.0
    ]
  end
end
