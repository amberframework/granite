# Granite

[Amber](https://github.com/amberframework/amber) is a web framework written in
the [Crystal](https://github.com/crystal-lang/crystal) language.

This project is to provide an ORM in Crystal.

[![Build Status](https://img.shields.io/travis/amberframework/granite.svg?maxAge=360)](https://travis-ci.org/amberframework/granite)

## Documentation

Start by checking out the [Getting Started](docs/getting_started.md) guide to get Granite installed and configured. For additional information visit the [Docs folder](docs/).

## Contributing

   1. Fork it ( https://github.com/amberframework/granite/fork )
   2. Create your feature branch (git checkout -b my-new-feature)
   3. Commit your changes (git commit -am 'Add some feature')
   4. Push to the branch (git push origin my-new-feature)
   5. Create a new Pull Request

   ## Running tests

   Granite uses Crystal's built in test framework. The tests can be run with `$ crystal spec`.

   The test suite depends on access to a PostgreSQL, MySQL, and SQLite database to ensure the adapters work as intended.

   ### Docker setup

   There is a self-contained testing environment provided via the `docker-compose.yml` file in this repository.
   We are testing against multiple databases so you have to specify which docker-compose file you would like to use.
   Replace "{database_type}" with "mysql" or "pg" or "sqlite". Before you can run the docker configuration you have to set the appropriate
   env variables. To do so you can either load them yourself or load the .env file

   ```
   $ source .env
   ```

   You can find postgres versions at https://hub.docker.com/_/postgres/
   You can find mysql versions at https://hub.docker.com/_/mysql/

   After you have docker installed do the following to run tests:

   #### First run

   ```
   $ docker-compose -f docker/docker-compose.{database_type}.yml build spec
   $ docker-compose -f docker/docker-compose.{database_type}.yml run spec
   ```

   #### Subsequent runs

   ```
   $ docker-compose -f docker/docker-compose.{database_type}.yml run spec
   ```

   #### Cleanup

   If you're done testing and you'd like to shut down and clean up the docker dependences run the following:

   ```
   $ docker-compose -f docker/docker-compose.{database_type}.yml down
   ```

   ### Local setup

   If you'd like to test without docker you can do so by following the instructions below:

   1. Install dependencies with `$ shards install `
   2. Update .env to use appropriate ENV variables, or create appropriate databases.
   3. Setup databases:

   #### PostgreSQL

   ```sql
   CREATE USER granite WITH PASSWORD 'password';

   CREATE DATABASE granite_db;

   GRANT ALL PRIVILEGES ON DATABASE granite_db TO granite;
   ```

   #### MySQL

   ```sql
   CREATE USER 'granite'@'localhost' IDENTIFIED BY 'password';

   CREATE DATABASE granite_db;

   GRANT ALL PRIVILEGES ON granite_db.* TO 'granite'@'localhost' WITH GRANT OPTION;
   ```

   4. Export `.env` with `$ source .env`
   5. `$ crystal spec`
