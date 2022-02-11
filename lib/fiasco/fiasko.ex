defmodule Fiasco.Application do
  @moduledoc """
  Documentation for Fiasco.
  """

  use Application
  require Logger

  def start(_type, _args) do
    ip = Application.get_env(:fiasco, :ip, {0, 0, 0, 0})
    port = Application.get_env(:fiasco, :port, 3000)

    Logger.info(
      "Launching application at ip:port " <> Kernel.inspect(ip) <> ":" <> Kernel.inspect(port)
    )

    children = [
      # Define workers and child supervisors to be supervised
      Plug.Adapters.Cowboy.child_spec(
        scheme: :http,
        plug: Fiasco.Router,
        options: [ip: ip, port: port]
      ),
      Fiasco.Repo,
      # calc p
      Fiasco.Game.Calculator,
      Fiasco.BSPSD,
      # Game main loop
      Fiasco.Game.Mainloop
    ]

    Logger.info("Starting supervisor")
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  def stop(_arg) do
    Logger.info("Application stopped")
  end
end
