# Fiasco

Fiasco service for OmCTF-2018.
It's a financial game. Clients of your bank system can play;

You make a bet with wish for the winner.
More you bet, more chances to win.


## Running

There is dockerfile. You can run service in container.
And there will be common docker-compose file for all game services.

## Start services
  # docker build -t omctf2018/fiasco .
  # docker run omctf2018/fiasco


  Later will be SHARED compose file for all services:
  # docker-compose up

## Common info

Written on Elixir (Erlang)
DB: sqlite3
External port: 3000
