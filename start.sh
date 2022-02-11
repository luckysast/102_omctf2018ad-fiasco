#!/bin/bash

if [ ! -f ./db/fiasco.sqlite3 ]; then
    echo "Remake db"
    ./remake.sh
fi

echo "Start app"
mix run --no-halt
