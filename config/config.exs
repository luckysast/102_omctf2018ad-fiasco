# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :fiasco, ecto_repos: [Fiasco.Repo]

config :fiasco, Fiasco.Repo,
  adapter: Sqlite.Ecto2,
  database: "/opt/fiasco/fiasco.sqlite3"

config :fiasco,
  # BSPS config
  bsps_ip: "bspsd-mock",
  bsps_port: 8800,
  time_round: 30,
  # fiasco
  ip: {0, 0, 0, 0},
  port: 3000

config :logger,
  # level: :debug
  level: :info

# The supported levels are:
#
#   :debug - for debug-related messages
#   :info - for information of any kind
#   :warn - for warnings
#   :error - for errors
