# Granite::ORM


[Amber](https://github.com/Amber-Crystal/amber) is a web framework written in
the [Crystal](https://github.com/manastech/crystal) language.

This project is to provide an ORM Model in Crystal.

## Installation

Add this library to your projects dependencies along with the driver in
your `shard.yml`.  This can be used with any framework but was originally
designed to work with kemalyst in mind.  This library will work with kemal as
well.

```yaml
dependencies:
  granite_orm:
    github: Amber-Crystal/granite-orm

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

Here is an example using Granite ORM Model

```crystal
require "granite_orm/adapter/mysql"

class Post < Granite::ORM::Base
  adapter mysql
  field name : String
  field body : Text
  timestamps
end
```

You can disable the timestamps for SqlLite since TIMESTAMP is not supported for this database:
```crystal
require "granite_orm/adapter/sqlite"

class Comment < Granite::ORM::Base
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
class Site < Granite::ORM::Base
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

#### First

```crystal
post = Post.first
if post
  puts post.name
end
```

#### Insert

```crystal
post = Post.new
post.name = "Granite ORM Rocks!"
post.body = "Check this out."
post.save
```

#### Update

```crystal
post = Post.find 1
post.name = "Granite Really Rocks!"
post.save
```

#### Delete

```crystal
post = Post.find 1
post.destroy
puts "deleted" unless post
```

### Relationships

`belongs_to` and `has_many` macros provide a rails like mapping between Objects.

```crystal
class User < Granite::ORM::Base
  adapter mysql
  
  has_many :posts
  
  field email : String
  field name : String
  timestamps
end


class Post < Granite::ORM::Base
  adapter mysql

  belongs_to :user
  
  field title : String
  timestamps
end
```

This will add a `posts` instance method to the user which returns an array of posts.
It will also add a `user` and `user=` methods to the post which returns and sets the user.
This also adds a field `user_id : Int64` to the field mapping.  

You will need to add a `user_id` and index to your posts table:
```mysql
CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  title VARCHAR,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE INDEX 'user_id_idx' ON TABLE posts (user_id);
```

### Errors

All database errors are added to the `errors` array used by Granite::ORM::Validators with the symbol ':base'
```
post = Post.new
post.save
post.errors[0].to_s.should eq "ERROR: name cannot be null"
```

### Queries

The where clause will give you full control over your query.

When using the `all` method, the SQL selected fields will always match the
fields specified in the model.

Always pass in parameters to avoid SQL Injection.  Use a `?`
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

It is common to only want the first result and append a `limit 1` to the query.
This is what the `first` method does.

For example:
```
post = Post.first("ORDER BY posts.name DESC")
```

This is the same as:
```
post = Post.all("ORDER BY posts.name DESC LIMIT 1").first
```


### Callbacks

There is support for callbacks on certain events.

Here is an example:
```crystal
require "granite_orm/adapter/pg"

class Post < Granite::ORM
  adapter pg

  before_save upcase_title # or :upcase_title

  field title : String
  field content : String
  timestamps

  def upcase_title
    if title = @title
      @title = title.upcase
    end
  end
end
```

You can register callbacks for the following events:

#### Create

- before_save
- before_create
- **save**
- after_create
- after_save

#### Update

- before_save
- before_update
- **save**
- after_update
- after_save

#### Destroy

- before_destroy
- **destroy**
- after_destroy

## Contributing

1. Fork it ( https://github.com/Amber-Crystal/granite-orm/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Running tests


1. Install dependencies with `$ crystal deps`
2. Update .env to use appropriate ENV variables, or create appropriate databases.

### PostgreSQL
```sql
CREATE USER granite WITH PASSWORD 'password';

CREATE DATABASE granite_db;

GRANT ALL PRIVILEGES ON DATABASE granite_db TO granite;
```
### MySQL
```sql
CREATE USER 'granite'@'localhost' IDENTIFIED BY 'password';

CREATE DATABASE granite_db;

GRANT ALL PRIVILEGES ON granite_db.* TO 'granite'@'localhost' WITH GRANT OPTION;
```

3. Export `.env` with `$ export .env`
4. `$ crystal spec`
