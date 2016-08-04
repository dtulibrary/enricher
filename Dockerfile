FROM debian:jessie

RUN apt-get clean
RUN apt-get update
RUN apt-get install -y wget
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i erlang-solutions_1.0_all.deb
RUN apt-get update
RUN apt-get install -y esl-erlang
RUN apt-get install -y elixir
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mkdir /app
WORKDIR /app
ADD . /app
RUN mix deps.get
