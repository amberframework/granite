#! /bin/bash

source ../.env

echo "Testing PG"

docker-compose -f docker/docker-compose.pg.yml build spec
docker-compose -f docker/docker-compose.pg.yml run spec

echo "Testing mysql"

docker-compose -f docker/docker-compose.mysql.yml build spec
docker-compose -f docker/docker-compose.mysql.yml run spec

echo "Testing sqlite"

docker-compose -f docker/docker-compose.sqlite.yml build spec
docker-compose -f docker/docker-compose.sqlite.yml run spec

echo "Done testing...stopping/removing images"

docker-compose -f docker/docker-compose.sqlite.yml down
docker-compose -f docker/docker-compose.mysql.yml down
docker-compose -f docker/docker-compose.pg.yml down
