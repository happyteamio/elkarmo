defmodule Elkarmo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :elkarmo,
      version: "0.2.0",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      extra_applications: [:logger],
      mod: {Elkarmo, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:slack, git: "https://github.com/BlakeWilliams/Elixir-Slack.git", tag: "v0.23.6"},
      {:distillery, "~> 1.5", runtime: false}
    ]
  end
end
