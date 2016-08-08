defmodule Enricher.Mixfile do
  use Mix.Project

  def project do
    [app: :enricher,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {Enricher, []},
      applications: [
        :logger,
        :httpoison,
        :exconstructor,
        :quantum
      ]
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
      {:httpoison, "~> 0.8"},
      {:poison, "~> 2.1"},
      {:exconstructor, "~> 1.0.2"},
      {:sweet_xml, "~> 0.6.1"},
      {:quantum, ">= 1.7.1"},
      {:logger_file_backend, "0.0.8"}
    ]
  end
end
