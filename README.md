# Granite

[Amber](https://github.com/amberframework/amber) is a web framework written in
the [Crystal](https://github.com/crystal-lang/crystal) language.

This project is to provide an ORM in Crystal.

# Looking for maintainers

Granite is looking for volunteers to take over maintainership of the repository, reviewing and merging pull requests, stewarding updates to follow along with Crystal language updates, etc. [More information here](https://github.com/amberframework/granite/issues/462)

## Documentation

[Documentation](docs/readme.md)

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

- You can find postgres versions at https://hub.docker.com/_/postgres/
- You can find mysql versions at https://hub.docker.com/_/mysql/

After you have docker installed do the following to run tests:
#### Environment variable setup
##### Option 1
Export `.env` with `$ source ./export.sh` or `$ source .env`.

##### Option 2
Modify the `.env` file that docker-compose loads by default. The `.env` file can either be copied to the same directory as the docker-compose.{database_type}.yml files or passed as an option to the docker-compose commands `--env-file ./foo/.env`.

#### First run
> Replace "{database_type}" with "mysql" or "pg" or "sqlite". 

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

#### Run all

To run the specs for each database adapter use `./spec/run_all_specs.sh`.    This will build and run each adapter, then cleanup after itself.

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

4. Export `.env` with `$ source ./export.sh` or `$ source .env`.
5. `$ crystal spec`
