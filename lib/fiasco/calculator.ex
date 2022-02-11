defmodule Fiasco.Game.Calculator do
  use GenServer
  require Logger

  def start_link(_arg) do
    Logger.info("Starting game calculator")
    GenServer.start_link(__MODULE__, %{}, name: Calc)
  end

  def init(state) do
    # Schedule work to be performed at some point
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    # Do the work you desire here
    schedule_work()
    {:noreply, state}
  end

  def handle_call(:recalc, _from, state) do
    calc_impact()

    {:reply, :ok, state}
  end

  defp calc_impact() do
    g =
      Fiasco.Model.Game
      |> Fiasco.Model.Game.getLastGame()
      |> Fiasco.Repo.one()

    if g != nil do
      Fiasco.Model.Bet
      |> Fiasco.Model.Bet.getUncalced()
      |> Fiasco.Repo.all()
      |> Enum.map(fn b ->
        b
        |> Fiasco.Model.Bet.changeset(%{impact: 1.0})
        |> Fiasco.Repo.update!()
      end)

      pot =
        Fiasco.Model.Bet
        |> Fiasco.Model.Bet.getGameBets(g.id)
        |> Fiasco.Repo.all()
        |> Enum.reduce(0, fn b, acc -> b.value + acc end)

      g
      |> Fiasco.Model.Game.changeset(%{pot: pot})
      |> Fiasco.Repo.update!()
    else
      Fiasco.Repo.insert!(%Fiasco.Model.Game{})
    end
  end

  defp schedule_work() do
    # In 5 sec
    Process.send_after(self(), :work, 5 * 1000)

    calc_impact()
  end
end
