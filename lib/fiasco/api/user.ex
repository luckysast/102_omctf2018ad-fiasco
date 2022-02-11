# API for session, user, account maipulations

defmodule Fiasco.API.User do
  import Plug.Conn
  require Logger

  def init(options), do: options

  # get info
  def call(%Plug.Conn{path_info: ["me"], method: "GET"} = conn, _params) do
    token = conn |> get_req_header("token") |> Enum.at(0)

    userid =
      case GenServer.call(BSPSD, {:userByToken, token}) do
        {:ok, uid} -> uid
        {:error, message} -> conn |> send_resp(400, Poison.encode!(message))
      end

    accounts =
      case GenServer.call(BSPSD, {:userAccounts, userid}) do
        {:ok, acc} ->
          if (acc != nil) do
            acc
          else
            []
          end
        {:error, message} -> conn |> send_resp(400, Poison.encode!(message))
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(accounts))
  end

  def call(%Plug.Conn{path_info: ["bets"], method: "GET"} = conn, _params) do
    token = conn |> get_req_header("token") |> Enum.at(0)

    userid =
      case GenServer.call(BSPSD, {:userByToken, token}) do
        {:ok, uid} -> uid
        {:error, message} -> conn |> send_resp(400, Poison.encode!(message))
      end

    # get bets by userid
    bets =
      Fiasco.Model.Bet
      |> Fiasco.Model.Bet.getUserBets(userid)
      |> Fiasco.Repo.all()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(bets))
  end

  def call(%Plug.Conn{path_info: ["wins"], method: "GET"} = conn, _params) do
    token = conn |> get_req_header("token") |> Enum.at(0)

    userid =
      case GenServer.call(BSPSD, {:userByToken, token}) do
        {:ok, uid} -> uid
        {:error, message} -> conn |> send_resp(400, Poison.encode!(message))
      end

    games =
      Fiasco.Model.Game
      |> Fiasco.Model.Game.getWinnedGames(userid)
      |> Fiasco.Repo.all()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(games))
  end

  # ////////////////////////////////////////////////////////////////////////////////////

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!("Default route for user API!"))
  end
end
