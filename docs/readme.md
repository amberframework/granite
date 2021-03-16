# Documentation

## Getting Started

### Installation

Add this library to your projects dependencies along with the driver in
your `shard.yml`.  This can be used with any framework but was originally
designed to work with the amber framework in mind.  This library will work
with Kemal or any other framework as well.

```yaml
dependencies:
  granite:
    github: amberframework/granite

  # Pick your database
  mysql:
    github: crystal-lang/crystal-mysql

  sqlite3:
    github: crystal-lang/crystal-sqlite3

  pg:
    github: will/crystal-pg

```

### Register a Connection

Next you will need to register a connection.  This should be one of the first things in your main Crystal file, before Granite is required.

```crystal
Granite::Connections << Granite::Adapter::Mysql.new(name: "mysql", url: "YOUR_DATABASE_URL")

# Rest of code...
```

Supported adapters include: `Mysql, Pg, and Sqlite`.

### Example Model

Here is an example Granite model using the connection registered above.

```crystal
require "granite/adapter/mysql"

class Post < Granite::Base
  connection mysql
  table posts # Name of the table to use for the model, defaults to class name snake cased

  column id : Int64, primary: true # Primary key, defaults to AUTO INCREMENT
  column name : String? # Nilable field
  column body : String # Not nil field
end
```

## Additional Documentation

[Models](./models.md)

[CRUD](./crud.md)

[Querying](./querying.md)

[Relationships](./relationships.md)

[Validation](./validations.md)

[Callbacks](./callbacks.md)

[Migrations](./migrations.md)

[Imports](./imports.md)

[Postgresql](./postgresql.md)
