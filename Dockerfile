FROM elixir:1.6 as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    && export LANG=en_US.UTF-8 \
    && echo $LANG UTF-8 > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=$LANG \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ENV MIX_ENV=prod

# Install Hex+Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /opt/elkarmo

# Cache elixir deps so that they won't be rebuilt if deps haven't changed
RUN mkdir config
COPY config/* config/
COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

COPY . .

RUN mix release --env=prod --verbose --no-tar

FROM debian:jessie

RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    libssl1.0.0 \
    && export LANG=en_US.UTF-8 \
    && echo $LANG UTF-8 > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=$LANG \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    REPLACE_OS_VARS=true \
    ERLANG_COOKIE=default_cookie \
    ELKARMO_SLACK_TOKEN=slack_token

COPY --from=builder /opt/elkarmo/_build/prod/rel/elkarmo /opt/elkarmo

RUN mkdir /opt/elkarmo/data

VOLUME ["/opt/elkarmo/data"]

ENTRYPOINT ["/opt/elkarmo/bin/elkarmo"]
CMD ["foreground"]
