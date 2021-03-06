FROM ubuntu:14.04.5

# Elixir requires UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Update and install some software requirements
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl build-essential wget git make postgresql inotify-tools xz-utils unzip screen

# For some reason, installing Elixir tries to remove this file
# and if it doesn't exist, Elixir won't install. So, we create it.
# Thanks Daniel Berkompas for this tip.
# http://blog.danielberkompas.com
RUN touch /etc/init.d/couchdb

# Install Node
ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 10.15.1

# install Node.js with package
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN apt-get install -y nodejs

# download and install Erlang package
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb \
 && dpkg -i erlang-solutions_1.0_all.deb \
 && apt-get update

ENV ERLANG_VERSION 1:21.2.5-1

# install Erlang
RUN apt-get install -y esl-erlang=$ERLANG_VERSION && rm erlang-solutions_1.0_all.deb

RUN apt-mark hold esl-erlang

ENV ELIXIR_VERSION 1.8.1

# install Elixir
RUN mkdir /opt/elixir \
  && cd /opt/elixir \
  && curl -O -L "https://github.com/elixir-lang/elixir/releases/download/v$ELIXIR_VERSION/Precompiled.zip" \
  && unzip Precompiled.zip \
  && cd /usr/local/bin \
  && ln -s /opt/elixir/bin/elixir \
  && ln -s /opt/elixir/bin/elixirc \
  && ln -s /opt/elixir/bin/iex \
  && ln -s /opt/elixir/bin/mix

# install Hex
RUN mix local.hex --force

ENV PHOENIX_VERSION 1.4.0

# install the Phoenix Mix archive
RUN mix archive.install --force hex phx_new $PHOENIX_VERSION

RUN mix hex.info

# include Dockerize to help launching containers
RUN wget https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-linux-amd64-v0.6.1.tar.gz
RUN tar -C /usr/local/bin -xzvf dockerize-linux-amd64-v0.6.1.tar.gz && rm dockerize-linux-amd64-v0.6.1.tar.gz

# include wait-for-it.sh
RUN curl -o /bin/wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh
RUN chmod a+x /bin/wait-for-it.sh

# install headless Chrome compatible with puppeteer
RUN apt-get update && apt-get install -yq libgconf-2-4
RUN apt-get update && apt-get install -y wget --no-install-recommends \
  && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  && apt-get update \
  && apt-get install -y google-chrome-unstable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst ttf-freefont \
    --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get purge --auto-remove -y curl \
  && rm -rf /src/*.deb

