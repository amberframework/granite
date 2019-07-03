# Model Usage

## Multiple Adapters

It is possible to register multiple adapters with different names/URLs, for example:

```Crystal
Granite::Adapters << Granite::Adapter::Mysql.new({name: "legacy_db", url: "LEGACY_DB_URL"})
Granite::Adapters << Granite::Adapter::Pg.new({name: "new_db", url: "NEW_DB_URL"})

class Foo < Granite::Base
  adapter legacy_db
  
  # model fields
end

class Bar < Granite::Base
  adapter new_db
  
  # model fields
end
```

In this example, model `Foo`, is connecting to a MySQL DB at the URL of `LEGACY_DB_URL` while model `Bar` is connecting to a Postgres DB at the URL `NEW_DB_URL`.  The adapter name given in the model maps to the name of a registered adapter. 

> **NOTE:** How you store/supply each adapter's URL is up to you; Granite only cares that it gets registered via `Granite::Adapters << adapter_object`.

## timestamps

The `timestamps` macro defines `created_at` and `updated_at` field for you.

```crystal
class Bar < Granite::Base
  adapter mysql
  # Other fields
  timestamps
end
```

Would be equivalent to:

```crystal
class Bar < Granite::Base
  adapter mysql
    
  field created_at : Time
  field updated_at : Time
end
```

## Custom Primary Key

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

## Natural Keys

For natural keys, you can set `auto: false` option to disable auto increment.

```crystal
class Site < Granite::Base
  adapter mysql
  primary code : String, auto: false
  field name : String
end
```

## UUIDs

For databases that utilize UUIDs as the primary key, the type of the primary key can be set to `UUID`.  This will generate a secure UUID when the model is saved.

```crystal
class Book < Granite::Base
  adapter mysql
  primary isbn : UUID
  field name : String
end

book = Book.new
book.name = "Moby Dick"
book.isbn # => nil
book.save
book.isbn # => RFC4122 V4 UUID string
```
## Default values

A default value can be assigned to a field that will be used if another value is not specified/supplies.

```Crystal
class Book < Granite::Base
  adapter mysql
  
  field name : String, default: "DefaultBook"
end

book = Book.new
book.name # => "DefaultBook"
```


## Generating Documentation

By default, running `crystal docs` will **not** include Granite methods, constants, and properties.  To include these, have an ENV variable: `DISABLE_GRANITE_DOCS=false` set before running `crystal docs`.

The `field` and `primary` macros have a comment option that will specify the documentation comment to apply to that property's getter and setter.

`field age : Int32, comment: "# Number of seconds since the post was posted"`

## Third-Party Annotations

Annotations can be a powerful method of adding property specific features with minimal amounts of code.  Since Granite utilizes the `property` keyword for its fields, annotations are able to be applied easily.  This is accomplished by using the `annotations` option on a field, similar to the `comment` option above.  It is used in the form of `annotations: ["annotation1", "annotation2"]`, for example:

```Crystal
class Foo < Granite::Base
  adapter mysql
  table_name foos

  field name : String
  field password : String, annotations: ["@[Foo::Options(option1: true)]", "@[Bar::Settings(other_option: 7)]"]
  field age : Int32
end
```

Notice the values of the array are exactly as what you would put on a normal property, just as strings.  In this case, Granite will apply the two annotations to the `password` property only.

## Converters

Granite supports custom/special types via converters.  Converters will convert the type into something the database can store when saving the model, and will convert the returned database value into that type on read.

Each converter has a `T` generic argument that tells the converter what type should be read from the `DB::ResultSet`.  For example, if you wanted to use the `UUID` converter and your underlying database column is `BLOB`, you would use `Bytes`, if it was `TEXT`, you would use `String`.

Currently Granite supports various converters, each with their own supported database column types:

- `Uuid(T)` - Converts a `UUID` to/from a database column of type `T`.  Supported types for `T` are: `String`, and `Bytes`.
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
  adapter mysql
  table_name foos

  # Other fields
  field status : OrderStatus, converter: Granite::Converters::Enum(OrderStatus, String) 
end
```
