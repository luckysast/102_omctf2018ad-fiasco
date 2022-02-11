#!/bin/sh

mix ecto.drop
mix ecto.create
mix ecto.migrate
