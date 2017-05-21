# kemalyst-model

[![Build Status](https://travis-ci.org/drujensen/kemalyst-model.svg)](https://travis-ci.org/drujensen/kemalyst-model)

[Documentation](http://drujensen.github.io/kemalyst-model/)

[Kemalyst](https://github.com/drujensen/kemalyst) is a web framework written in
the [Crystal](https://github.com/manastech/crystal) language.

This project is to provide an ORM Model for Kemalyst.

## Installation

Add this library to your projects dependencies along with the driver in
your `shard.yml`.  This can be used with any framework but was originally
designed to work with kemalyst in mind.  This library will work with kemal as
well.

```yaml
dependencies:
  kemalyst-model:
    github: drujensen/kemalyst-model

  # Pick your database
  mysql:
    github: crystal-lang/crystal-mysql

  sqlite3:
    github: crystal-lang/crystal-sqlite3

  pg:
    github: will/crystal-pg

```

Next you will need to create a `config/database.yml`
You can leverage environment variables using ${} syntax.

```yaml
mysql:
  database: "mysql://user:pass@mysql:3306/test"
pg:
  database: "postgres://postgres:@pg:5432/postgres"
sqlite:
  database: "sqlite3:./config/test.db"
```

Or you can set the `DATABASE_URL` environment variable.  This will override the config/database.yml

## Usage

Here is an example using Kemalyst Model

```crystal
require "kemalyst-model/adapter/mysql"

class Post < Granite::ORM
  adapter mysql
  field name : String
  field body : Text
  timestamps
end
```

You can disable the timestamps for SqlLite since TIMESTAMP is not supported for this database:
```crystal
require "kemalyst-model/adapter/sqlite"

class Comment < Granite::ORM
  adapter sqlite
  table_name post_comments
  field name : String
  field body : Text
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
  PRIMARY KEY (id)
```

### Custom Primary Key

For legacy database mappings, you may already have a table and the primary key is not named `id` or `Int64`.

We have a macro called `primary` to help you out:

```crystal
class Site < Granite::ORM
  adapter mysql
  primary custom_id : Int32
  field name : String
end
```

This will override the default primary key of `id : Int64`.

### SQL

To clear all the rows in the database:
```crystal
Post.clear #truncate the table
```

#### Find All

```crystal
posts = Post.all
if posts
  posts.each do |post|
    puts post.name
  end
end
```

#### Find

```crystal
post = Post.find 1
if post
  puts post.name
end
```

#### Find By

```crystal
post = Post.find_by :slug, "example_slug"
if post
  puts post.name
end
```

#### Insert

```crystal
post = Post.new
post.name = "Kemalyst Rocks!"
post.body = "Check this out."
post.save
```

#### Update

```crystal
post = Post.find 1
post.name = "Kemalyst Really Rocks!"
post.save
```

#### Delete

```crystal
post = Post.find 1
post.destroy
puts "deleted" unless post
```

### Errors

All database errors are added to the `errors` array used by Kemalyst::Validators with the symbol ':base'
```
post = Post.new
post.save
post.errors[0].to_s.should eq "ERROR: name cannot be null"
```

### Queries

The where clause will give you full control over your query.

When using the `all` method, the SQL selected fields will always match the
fields specified in the model.

Always pass in parameters to avoid SQL Injection.  Use a `?` (or `$1`, `$2`,.. for pg)
in your query as placeholder. Checkout the [Crystal DB Driver](https://github.com/crystal-lang/crystal-db)
for documentation of the drivers.

Here are some examples:
```crystal
posts = Post.all("WHERE name LIKE ?", ["Joe%"])
if posts
  posts.each do |post|
    puts post.name
  end
end

# ORDER BY Example
posts = Post.all("ORDER BY created_at DESC")

# JOIN Example
posts = Post.all("JOIN comments c ON c.post_id = post.id
                  WHERE c.name = ?
                  ORDER BY post.created_at DESC",
                  ["Joe"])

```
## Contributing

1. Fork it ( https://github.com/drujensen/kemalyst-model/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [drujensen](https://github.com/drujensen) drujensen - creator, maintainer
