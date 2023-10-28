FROM 84codes/crystal:latest-ubuntu-jammy

# Install deps
RUN apt-get update -qq && apt-get install -y --no-install-recommends libpq-dev libmysqlclient-dev libsqlite3-dev

WORKDIR /app/user

COPY shard.yml /app/user
COPY shard.lock /app/user
RUN shards install

COPY src /app/user/src
COPY spec /app/user/spec

ENTRYPOINT []
