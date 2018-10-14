FROM crystallang/crystal:0.26.0

RUN apt-get update -qq && apt-get install -y --no-install-recommends libpq-dev libsqlite3-dev libmysqlclient-dev

WORKDIR /app/user

COPY shard.yml ./
RUN shards install

COPY . /app/user

CMD ["crystal", "spec"]

