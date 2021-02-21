# Model Usage

## Multiple Connections

It is possible to register multiple connections, for example:

```crystal
Granite::Connections << Granite::Adapter::Mysql.new(name: "legacy_db", url: "LEGACY_DB_URL")
Granite::Connections << Granite::Adapter::Pg.new(name: "new_db", url: "NEW_DB_URL")

class Foo < Granite::Base
  connection legacy_db

  # model fields
end

class Bar < Granite::Base
  connection new_db

  # model fields
end
```

In this example, we defined two connections.  One to a MySQL database named "legacy_db", and another to a PG database named "new_db".  The connection name given in the model maps to the name of a registered connection. 

> **NOTE:** How you store/supply each connection's URL is up to you; Granite only cares that it gets registered via `Granite::Connections << adapter_object`.

## timestamps

The `timestamps` macro defines `created_at` and `updated_at` field for you.

```crystal
class Bar < Granite::Base
  connection mysql

  # Other fields
  timestamps
end
```

Would be equivalent to:

```crystal
class Bar < Granite::Base
  connection mysql

  column created_at : Time?
  column updated_at : Time?
end
```

## Primary Keys

Each model is required to have a primary key defined.  Use the `column` macro with the `primary: true` option to denote the primary key. 

> **NOTE:** Composite primary keys are not yet supported.
```crystal
class Site < Granite::Base
  connection mysql

  column id : Int64, primary: true
  column name : String
end
```

`belongs_to` associations can also be used as a primary key in much the same way.

```crystal
class ChatSettings < Granite::Base
  connection mysql

  # chat_id would be the primary key
  belongs_to chat : Chat, primary: true
end
```

### Custom

The name and type of the primary key can also be changed from the recommended `id : Int64`.

```crystal
class Site < Granite::Base
  connection mysql

  column custom_id : Int32, primary: true
  column name : String
end
```

### Natural Keys

Primary keys are defined as auto incrementing by default.  For natural keys, you can set `auto: false` option.

```crystal
class Site < Granite::Base
  connection mysql

  column custom_id : Int32, primary: true, auto: false
  column name : String
end
```

### UUIDs

For databases that utilize UUIDs as the primary key, the type of the primary key can be set to `UUID`.  This will generate a secure UUID when the model is saved.

```crystal
class Book < Granite::Base
  connection mysql

  column isbn : UUID, primary: true
  column name : String
end

book = Book.new
book.name = "Moby Dick"
book.isbn # => nil
book.save
book.isbn # => RFC4122 V4 UUID string
```
## Default values

A default value can be defined that will be used if another value is not specified/supplied.

```crystal
class Book < Granite::Base
  connection mysql

  column id : Int64, primary: true
  column name : String = "DefaultBook"
end

book = Book.new
book.name # => "DefaultBook"
```

## Generating Documentation

By default, running `crystal docs` will **not** include Granite methods, constants, and properties.  To include these, use the `granite_docs` flag when generating the documentation.  E.x. `crystal docs -D granite_docs`.

Doc block comments can be applied above the `column` macro.

```crystal
# If the item is public.
column published : Bool
```

## Annotations

Annotations can be a powerful method of adding property specific features with minimal amounts of code.  Since Granite utilizes the `property` keyword for its columns, annotations are able to be applied easily.  These can either be `JSON::Field`, `YAML::Field`, or third party annotations.

```crystal
class Foo < Granite::Base
  connection mysql
  table foos

  column id : Int64, primary: true

  @[JSON::Field(ignore: true)]
  @[Bar::Settings(other_option: 7)]
  column password : String

  column name : String
  column age : Int32
end
```

## Converters

Granite supports custom/special types via converters.  Converters will convert the type into something the database can store when saving the model, and will convert the returned database value into that type on read.

Each converter has a `T` generic argument that tells the converter what type should be read from the `DB::ResultSet`.  For example, if you wanted to use the `JSON` converter and your underlying database column is `BLOB`, you would use `Bytes`, if it was `TEXT`, you would use `String`.

Currently Granite supports various converters, each with their own supported database column types:

- `Enum(E, T)` - Converts an Enum of type `E` to/from a database column of type `T`. Supported types for `T` are: `Number`, `String`, and `Bytes`.
- `Json(M, T)` - Converters an `Object` of type `M` to/from a database column of type `T.`  Supported types for `T` are: `String`, `JSON::Any`, and `Bytes`.
  - **NOTE:**  `M` must implement `#to_json` and `.from_json` methods.
- `PgNumeric` - Converts a `PG::Numeric` value to a `Float64` on read.

The converter is defined on a per field basis.  This example has an `OrderStatus` enum typed field.  When saved, the enum value would be converted to a string to be stored in the DB.  Then, when read, the string would be used to parse a new instance of `OrderStatus`.

```crystal
enum OrderStatus
  Active
  Expired
  Completed
end

class Order < Granite::Base
  connection mysql
  table foos

  # Other fields
  column status : OrderStatus, converter: Granite::Converters::Enum(OrderStatus, String) 
end
```

## Serialization

Granite implements [JSON::Serializable](https://crystal-lang.org/api/JSON/Serializable.html) and [YAML::Serializable](https://crystal-lang.org/api/YAML/Serializable.html) by default.  As such, models can be serialized to/from JSON/YAML via the `#to_json`/`#to_yaml` and `.from_json`/`.from_yaml` methods.
