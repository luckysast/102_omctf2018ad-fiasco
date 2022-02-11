defmodule Fiasco.Router do
  use Plug.Router
  use Plug.ErrorHandler

  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:json],
    json_decoder: Poison
  )

  plug(:match)
  plug(:dispatch)

  get "/check" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      200,
      Poison.encode!(%{"game" => "Fiasco", "status" => "OK", "magic number" => 42})
    )
  end

  forward("/user", to: Fiasco.API.User)
  forward("/game", to: Fiasco.API.Game)

  # get "/hello/:name" do
  #   send_resp(conn, 200, "Hello dear " <> name)
  # end

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, conn.status, Poison.encode!("Something went wrong"))
  end
end
