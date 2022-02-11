defmodule Fiasco.Game.Mainloop do
  use GenServer
  require Logger

  def start_link(_arg) do
    Logger.info("Starting main game loop")
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    :rand.seed(:exs1024)
    # :rand.seed(:os.timestamp)
    # Schedule work to be performed at some point
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    # Do the work you desire here
    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    round = Application.get_env(:fiasco, :time_round, 180)
    # In 10 sec
    Process.send_after(self(), :work, round * 1000)
    # Logger.info "Ping!"

    # intercommunicate (ask calc to run manually)
    GenServer.call(Calc, :recalc)

    g =
      Fiasco.Model.Game
      |> Fiasco.Model.Game.getLastGame()
      |> Fiasco.Repo.one()

      if (g != nil) do
        bets =
          Fiasco.Model.Bet
          |> Fiasco.Model.Bet.getGameBets(g.id)
          |> Fiasco.Repo.all()

          total_i =
            bets
            |> Enum.reduce(0, fn b, acc -> b.impact + acc end)

            # |> Enum.map(fn b -> Logger.debug inspect(b) end)
            winner =
              bets
              |> Enum.reduce_while(total_i, fn b, acc ->
                if :rand.uniform() < b.impact / acc do
                  {:halt, b}
                else
                  {:cont, acc - b.impact}
                end
              end)

              if winner != 0 do
                transfer =
                  case GenServer.call(BSPSD, {:transferMoney, g.service_account, winner.account_id, g.pot}) do
                    {:ok, _val} -> :ok
                    {:error, message} -> Logger.error(inspect(message))
                  end

                  if transfer == :ok do
                    g
                    |> Fiasco.Model.Game.changeset(%{winner_id: winner.user_id})
                    |> Fiasco.Repo.update!()
                  end
                end

                Logger.info("Round is over, past game info: " <> inspect(g))
      end

    # create new game
    name =
      if (g == nil) do
        "fs_0_" <> to_string(Float.floor(:rand.uniform()*100000, 2))
      else
        "fs_" <> to_string(g.id+1) <> "_" <> to_string(Float.floor(:rand.uniform()*100000, 2))
      end

    accid =
      case GenServer.call(BSPSD, {:createAccount, name}) do
        {:ok, accid} -> accid
        {:error, message} -> Logger.error inspect(message)
      end

    Fiasco.Repo.insert!(%Fiasco.Model.Game{
      service_account: accid
      })

  end
end
