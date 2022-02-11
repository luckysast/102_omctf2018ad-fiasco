#!/usr/bin/docker build -t fiasco .

FROM elixir:latest
MAINTAINER LSD, jannoterr@gmail.com

LABEL Description="omctf2018-fiasco-service" Author="LSD"

RUN mkdir ~/fiasco
COPY . ~/fiasco
WORKDIR ~/fiasco

RUN mix local.hex --force
RUN mix deps.get
RUN mix local.rebar --force
#RUN ./remake.sh

EXPOSE 3000
ENTRYPOINT ["./start.sh"]
