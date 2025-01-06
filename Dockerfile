# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.4.1
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

ARG NODE_VERSION=22.12.0
ARG NODE_ENV=development
ARG NVM_DIR=/usr/local/nvm
ARG NVM_BIN=$NVM_DIR/versions/node/v$NODE_VERSION/bin

ENV NVM_DIR $NVM_DIR
ENV PATH $NVM_BIN:$PATH

ENV EDITOR vim
ENV VISUAL $EDITOR

# Ref: https://bundler.io/guides/bundler_docker_guide.html
ENV GEM_HOME="/usr/local/bundle"
ENV PATH $GEM_HOME/bin:$GEM_HOME/gems/bin:$PATH

RUN (apt update -y || /bin/true) && \
  apt install -y -q --no-install-recommends \
    build-essential \
    curl \
    file \
    git \
    imagemagick \
    libjemalloc2 \
    libpq-dev \
    libvips \
    neovim \
    pkg-config \
    silversearcher-ag \
    tmux && \
  curl -L https://github.com/DarthSim/overmind/releases/download/v2.4.0/overmind-v2.4.0-linux-amd64.gz | gzip -d > /usr/local/bin/overmind && \
  chmod +x /usr/local/bin/overmind && \
  apt clean all && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

RUN mkdir $NVM_DIR && \
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && \
  . $NVM_DIR/nvm.sh && \
  nvm install $NODE_VERSION && \
  nvm alias default $NODE_VERSION && \
  nvm use default && \
  npm i -g bun
