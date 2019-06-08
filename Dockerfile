FROM crystallang/crystal:0.29.0

ARG sqlite_version=3110000
ARG sqlite_version_year=2016

# Install deps
RUN apt-get update -qq && apt-get install -y --no-install-recommends libpq-dev libmysqlclient-dev libsqlite3-dev wget unzip lib32z1

WORKDIR /app/user

COPY shard.yml ./
RUN shards install

COPY . /app/user

RUN wget -O sqlite.zip https://www.sqlite.org/$sqlite_version_year/sqlite-tools-linux-x86-$sqlite_version.zip && unzip -d /usr/bin/ -j sqlite.zip && rm sqlite.zip
