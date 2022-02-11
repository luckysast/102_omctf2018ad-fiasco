defmodule Fiasco.MixProject do
  use Mix.Project

  def project do
    [
      app: :fiasco,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:ecto, :cowboy, :plug],
      extra_applications: [:logger],
      mod: {Fiasco.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # JSON lib
      {:poison, "~> 3.1"},
      # {:json, "~> 1.2"},
      # web server
      {:cowboy, "~> 1.0.0"},
      # endpoints (router)
      {:plug, "~> 1.0"},
      # DB manager
      {:ecto, "~> 2.1"},
      # DB connector
      {:sqlite_ecto2, "~> 2.2"},
      # socket (web)
      {:socket, "~> 0.3"}
    ]
  end
end
