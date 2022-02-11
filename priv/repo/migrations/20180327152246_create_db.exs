defmodule Fiasco.Repo.Migrations.SetUp do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :winner_id, :string, null: true
      add :bets, references(:bets), null: true
      add :pot, :float
      add :service_account, :integer

      timestamps()
      # add :players_ids, references(:users)
    end

    create table(:bets) do
      add :game_id, references(:games)
      add :account_id, :integer, null: false
      add :user_id, :string, null: false
      add :value, :float, null: false
      add :comment, :string, size: 60
      add :impact, :float, default: 0.0

      timestamps()
    end

    # create(unique_index(:users, [:userid], name: :unique_users_ids))
    # create(unique_index(:users, [:token], name: :unique_users_tokens))
  end
end
