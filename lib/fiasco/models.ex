defmodule Fiasco.Model.Game do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  @derive {Poison.Encoder, only: [:id, :pot, :players, :winner_id]}
  schema "games" do
    field(:pot, :float, default: 0.0)
    # winner bet userID
    field(:winner_id, :string)
    field(:service_account, :integer)

    has_many(:players, Fiasco.Model.Bet)

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pot, :winner_id])
  end

  # game by id
  def getByID(query, game_id) do
    query
    |> where([g], g.id == ^game_id)
    |> preload([:players])
  end

  # only id
  def getLastGame(query) do
    query
    |> order_by([g], desc: g.id)
    |> limit(1)
  end

  def getLastGames(query, c) do
    query
    |> order_by([g], desc: g.id)
    |> limit(^c)
  end

  # preload players and winner
  def getLastGameStatus(query) do
    query
    |> order_by([g], desc: g.id)
    |> limit(1)
    |> preload([:players])
  end

  def getWinnedGames(query, winner_id) do
    query
    |> where([g], g.winner_id == ^winner_id)
    |> preload([:players])
  end
end

defmodule Fiasco.Model.Bet do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  @derive {Poison.Encoder,
           only: [:id, :game_id, :account_id, :user_id, :value, :comment, :impact]}
  schema "bets" do
    belongs_to(:game, Fiasco.Model.Game)
    field(:account_id, :integer)
    field(:user_id, :string)
    field(:comment, :string)
    field(:value, :float)
    field(:impact, :float)

    timestamps()
  end

  defp calc_impact(changeset) do
    if get_change(changeset, :impact) do
      i = get_field(changeset, :value, 2.14)
      c = get_field(changeset, :comment, "it's FIASCO brother")

      i = 0.1 + :math.log2(:math.log2(i))

      {l, r} =
        to_charlist(c)
        |> Enum.map_reduce(1, fn x, acc -> {rem(x * acc, 255), x + acc} end)

      l = rem(Enum.reduce(l, fn x, acc -> x + acc end), 255)
      z = i * rem(r, l)

      changeset
      |> put_change(:impact, z)
    else
      changeset
    end
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:comment, :impact])
    |> calc_impact
  end

  def getUserBets(query, user_id) do
    query
    |> where([b], b.user_id == ^user_id)
  end

  def getGameBets(query, game_id) do
    query
    |> where([b], b.game_id == ^game_id)
  end

  def getUncalced(query) do
    query
    |> where([b], b.impact <= 0.0)
  end
end
