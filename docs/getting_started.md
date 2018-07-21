# Getting Started

## Installation

Add this library to your projects dependencies along with the driver in
your `shard.yml`.  This can be used with any framework but was originally
designed to work with the amber framework in mind.  This library will work
with kemal or any other framework as well.

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

Next you will need to create a `config/database.yml`
You can leverage environment variables using `${}` syntax.

```yaml
mysql:
  database: "mysql://username:password@hostname:3306/database_${AMBER_ENV}"
pg:
  database: "postgres://username:password@hostname:5432/database"
sqlite:
  database: "sqlite3:./config/${DB_NAME}.db"
```

Or you can set the `DATABASE_URL` environment variable.  This will override the config/database.yml

## Usage

Here is an example using Granite Model

```crystal
require "granite/adapter/mysql"

class Post < Granite::Base
  adapter mysql
  field name : String
  field body : String
  timestamps
end
```

### id, created_at, updated_at

The primary key is automatically created for you and if you use `timestamps` they will be
automatically updated for you.

Here are the MySQL field definitions for id, created_at, updated_at

```mysql
  id BIGINT NOT NULL AUTO_INCREMENT
  # Your fields go here
  created_at TIMESTAMP
  updated_at TIMESTAMP
```

### Custom Primary Key

For legacy database mappings, you may already have a table and the primary key is not named `id` or `Int64`.

Use the `primary` macro to define your own primary key

```crystal
class Site < Granite::Base
  adapter mysql
  primary custom_id : Int32
  field name : String
end
```

This will override the default primary key of `id : Int64`.

### Natural Keys

For natural keys, you can set `auto: false` option to disable auto increment.

```crystal
class Site < Granite::Base
  adapter mysql
  primary code : String, auto: false
  field name : String
end
```

### UUIDs

For databases that utilize UUIDs as the primary key, the `primary` macro can be used again with the `auto: false` option.  A `before_create` callback can be added to the model to randomly generate and set a secure UUID on the record before it is saved to the database.

```crystal
class Book < Granite::Base
  require "uuid"
  adapter mysql
  primary ISBN : String, auto: false
  field name : String

  before_create :assign_isbn

  def assign_isbn
    @ISBN = UUID.random.to_s
  end
end
```

### Generating Documentation

By default, running `crystal docs` will include Granite methods, constants, and properties.  To exclude these, have an ENV variable: `DISABLE_GRANITE_DOCS=true` set before running `crystal docs`.

The `field` and `primary` macros have a comment option that will specify the documentation comment to apply to that property's getter and setter.

`field age : Int32, comment: "# Number of seconds since the post was posted"`


See the [Docs folder](./) for additional information.