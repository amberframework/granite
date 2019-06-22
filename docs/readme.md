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

### Register an Adapter

Next you will need to register an adapter.  This should be one of the first things in your main Crystal file, before Granite is required.

```crystal
Granite::Adapters << Granite::Adapter::Mysql.new({name: "mysql", url: "YOUR_DATABASE_URL"})

# Rest of code...
```

Supported adapters include `Mysql, Pg, and Sqlite`.

### Example Model

Here is an example Granite model using the adapter registered above.

```crystal
require "granite/adapter/mysql"

class Post < Granite::Base
  adapter mysql
  # Primary key, unless explicitly specified, is assumed to be Int64 AUTO INCREMENT
  field name : String # Nilable field
  field! body : String # Not nil field
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

[JSON Support](./json_support.md)

[YAML Support](./yaml_support.md)
