# Getting Started

## Installation

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

Next you will need to register an adapter.  This should be one of the first things in your main Crystal file, before Granite is required.

```crystal
Granite::Adapters << Granite::Adapter::Mysql.new({name: "mysql", url: "YOUR_DATABASE_URL"})

# Rest of code...
```

Supported adapters include `Mysql, Pg, and Sqlite`.

## Usage

### Adapters

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

This model is using an adapter named `mysql`, registered in the example above.  It is possible to register multiple adapters with different names/URLs, for example:

```Crystal
Granite::Adapters << Granite::Adapter::Mysql.new({name: "LegacyDB", url: "LEGACY_DB_URL"})
Granite::Adapters << Granite::Adapter::Pg.new({name: "NewDb", url: "NEW_DB_URL"})

class Foo < Granite::Base
  adapter LegacyDB
  
  # model fields
end

class Bar < Granite::Base
  adapter NewDb
  
  # model fields
end
```

In this example, model `Foo`, is connecting to a MySQL DB at the URL of `LEGACY_DB_URL` while model `Bar` is connecting to a Postgres DB at the URL `NEW_DB_URL`.  The adapter name given in the model maps to the name of a registered adapter. 

**NOTE: How you store/supply each adapter's URL is up to you; Granite only cares that it gets registered via `Granite::Adapters << adapter_object`.**

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

By default, running `crystal docs` will **not** include Granite methods, constants, and properties.  To include these, have an ENV variable: `DISABLE_GRANITE_DOCS=false` set before running `crystal docs`.

The `field` and `primary` macros have a comment option that will specify the documentation comment to apply to that property's getter and setter.

`field age : Int32, comment: "# Number of seconds since the post was posted"`

See the [Docs folder](./) for additional information.
