# API for game mechanics
# get info about current game, get history info, get current chances

defmodule Fiasco.API.Game do
  import Plug.Conn
  require Logger

  def init(options), do: options

  def call(%Plug.Conn{path_info: ["recent"], method: "GET"} = conn, _params) do

    g =
      Fiasco.Model.Game
      |> Fiasco.Model.Game.getLastGames(10)
      |> Fiasco.Repo.all()

    if g == nil do
      conn |> send_resp(500, Poison.encode!(%{"error" => "There is no games yet"}))
    end

    g = %{g | players: []}

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(g))
  end

  def call(%Plug.Conn{path_info: ["now"], method: "GET"} = conn, _params) do
    # conn = fetch_cookies(conn)
    # token = conn.cookies["token"]
    token = conn |> get_req_header("token") |> Enum.at(0)

    userid =
      cond do
        token == nil ->
          nil

        true ->
          case GenServer.call(BSPSD, {:userByToken, token}) do
            {:ok, uid} -> uid
            {:error, _message} -> nil
          end
      end

    g =
      Fiasco.Model.Game
      |> Fiasco.Model.Game.getLastGameStatus()
      |> Fiasco.Repo.one()

    if g == nil do
      conn |> send_resp(500, Poison.encode!(%{"error" => "There is no games yet"}))
    end

    %Fiasco.Model.Game{players: pls} = g
    pls = Enum.map(pls, fn p -> %{p | comment: "Wish to winner, now it is a secret"} end)
    g = %{g | players: pls}

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(g))
  end

  def call(%Plug.Conn{path_info: ["now"], method: "PUT"} = conn, _params) do
    token = conn |> get_req_header("token") |> Enum.at(0)

    # try to make transaction from given accountid to pot
    userid =
      case GenServer.call(BSPSD, {:userByToken, token}) do
        {:ok, uid} -> uid
        {:error, message} -> conn |> send_resp(400, Poison.encode!(message))
      end

    # get last game
    g =
      Fiasco.Model.Game
      |> Fiasco.Model.Game.getLastGame()
      |> Fiasco.Repo.one()

    aid = conn.body_params["accountID"]
    c = conn.body_params["comment"]
    value = conn.body_params["amount"]

    Logger.info(inspect(aid))

    transfer =
      case GenServer.call(BSPSD, {:transferMoney, aid, g.service_account, value}) do
        {:ok, _val} -> :ok
        {:error, message} -> conn |> send_resp(400, Poison.encode!(message))
      end

    case Fiasco.Repo.insert(%Fiasco.Model.Bet{
           game: g,
           account_id: aid,
           user_id: userid,
           comment: c,
           value: value
         }) do
      {:ok, b} ->
        conn |> send_resp(200, Poison.encode!(b))

      {:error, _changeset} ->
        conn
        |> send_resp(500, Poison.encode!(%{"error" => "Service error, u loose monry, sorry"}))

        # conn |> send_resp(400, Poison.encode!("cant bet, sorry")) # Something went wrong
    end
  end

  # get finished game (by id)
  def call(%Plug.Conn{method: "GET"} = conn, _params) do
    token = conn |> get_req_header("token") |> Enum.at(0)

      userid =
      case GenServer.call(BSPSD, {:userByToken, token}) do
        {:ok, uid} -> uid
        {:error, message} -> nil
      end

    gid =
      conn.path_params["glob"]
      |> Enum.at(0)
      |> String.to_integer()

    uid =
      conn.path_params["glob"]
      |> Enum.at(1, nil)

    # # get last game
    g =
      Fiasco.Model.Game
      |> Fiasco.Model.Game.getByID(gid)
      |> Fiasco.Repo.one()

    cond do
      g == nil ->
        conn |> send_resp(400, Poison.encode!(%{"error" => "Can't find this game"}))

        # userid == g.winner_id ->
      uid == g.winner_id ->
        conn |> send_resp(200, Poison.encode!(g))

      true ->
        %Fiasco.Model.Game{players: pls} = g

        pls =
          Enum.map(pls, fn p -> %{p | comment: "Its a FIASCO, bro!"} end)
          |> Enum.filter(fn p ->
            cond do
              uid == nil ->
                true

              p.user_id == uid ->
                true

              true ->
                false
            end
          end)

        g = %{g | players: pls}
        conn |> send_resp(200, Poison.encode!(g))
    end

    # if g == nil do
    #   conn |> send_resp(400, Poison.encode!("Can't find this game"))
    # else
    #   conn |> send_resp(200, Poison.encode!(g))
    # end
  end

  # ////////////////////////////////////////////////////////////////////////////////////

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, Poison.encode!("Default route for game API!"))
  end
end
