FROM debian:jessie

# Update packages
RUN apt-get clean
RUN apt-get update

# Set the locale
RUN apt-get install -y locales -qq && locale-gen en_US.UTF-8 en_us && dpkg-reconfigure locales && dpkg-reconfigure locales && locale-gen C.UTF-8 && /usr/sbin/update-locale LANG=C.UTF-8
ENV LANG C.UTF-8
ENV LANGUAGE C.UTF-8
ENV LC_ALL C.UTF-8

# Install Elixir
RUN apt-get install -y wget
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i erlang-solutions_1.0_all.deb
RUN apt-get clean && apt-get update
RUN apt-get install -y esl-erlang
RUN apt-get install -y elixir

# Install Elixir build dependencies
RUN mix local.hex --force
RUN mix local.rebar --force

# Mount application
RUN mkdir /app
WORKDIR /app
ADD . /app

# Install app dependencies
RUN mix deps.get
