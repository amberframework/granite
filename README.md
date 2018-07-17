# Granite

[Amber](https://github.com/amberframework/amber) is a web framework written in
the [Crystal](https://github.com/crystal-lang/crystal) language.

This project is to provide an ORM in Crystal.

[![Build Status](https://img.shields.io/travis/amberframework/granite.svg?maxAge=360)](https://travis-ci.org/amberframework/granite)

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

```crystal
require "granite/adapter/mysql"

class Post < Granite::Base
  adapter mysql
  field name : String
  field body : String
  timestamps
end

# There are various ways to instantiate a new object:
namedTuple = Post.new(name: "Name", body: "I am the body") # .new NamedTuple
hash = Post.new({name: "Name", body: "I am the body"}.to_h) # .new Hash
fromJson = Post.from_json(JSON.parse(%({"name": "Name", "body": "I am the body"}))) # .from_json JSON
jsonArray = Array(Post).from_json(JSON.parse(%([{"name": "Post1", "body": "I am the body for post1"},{"name": "Post2", "body": "I am the body for post2"}]))) # .from_json array of JSON

# Can also use .create to automatically instantiate and save a model
Post.create(name: "First Post", body: "I get saved automatically") # Instantiates and saved the post
```
**Note:  When using `.from_json/.to_json` see [JSON::Serialization](https://crystal-lang.org/api/0.25.1/JSON/Serializable.html) for more details.**

You can disable the timestamps for SqlLite since TIMESTAMP is not supported for this database:

```crystal
require "granite/adapter/sqlite"

class Comment < Granite::Base
  adapter sqlite
  table_name post_comments
  field name : String
  field body : String
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
class Site < Granite::Base
  adapter mysql
  primary custom_id : Int32
  field name : String
end
```

This will override the default primary key of `id : Int64`.

#### Natural Keys

For natural keys, you can set `auto: false` option to disable auto increment insert.

```crystal
class Site < Granite::Base
  adapter mysql
  primary code : String, auto: false
  field name : String
end
```

#### UUIDs

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

### Bulk Insertions

#### Import

**Note:  Imports do not trigger callbacks automatically.  See [Running Callbacks](#running-callbacks).**

Each model has an `import` class level method to import an array of models in one bulk insert statement.
```Crystal
models = [
  Model.new(id: 1, name: "Fred", age: 14),
  Model.new(id: 2, name: "Joe", age: 25),
  Model.new(id: 3, name: "John", age: 30),
]

Model.import(models)
```

#### update_on_duplicate

The `import` method has an optional `update_on_duplicate`  + `columns` params that allows you to specify the columns (as an array of strings) that should be updated if primary constraint is violated.
```Crystal
models = [
  Model.new(id: 1, name: "Fred", age: 14),
  Model.new(id: 2, name: "Joe", age: 25),
  Model.new(id: 3, name: "John", age: 30),
]

Model.import(models)

Model.find!(1).name # => Fred

models = [
  Model.new(id: 1, name: "George", age: 14),
]

Model.import(models, update_on_duplicate: true, columns: %w(name))

Model.find!(1).name # => George
```

**NOTE:  If using PostgreSQL you must have version 9.5+ to have the on_duplicate_key_update feature.**

#### ignore_on_duplicate

The `import` method has an optional `ignore_on_duplicate` param, that takes a boolean, which will skip records if the primary constraint is violated.
```Crystal
models = [
  Model.new(id: 1, name: "Fred", age: 14),
  Model.new(id: 2, name: "Joe", age: 25),
  Model.new(id: 3, name: "John", age: 30),
]

Model.import(models)

Model.find!(1).name # => Fred

models = [
  Model.new(id: 1, name: "George", age: 14),
]

Model.import(models, ignore_on_duplicate: true)

Model.find!(1).name # => Fred
```

#### batch_size

The `import` method has an optional `batch_size` param, that takes an integer.  The batch_size determines the number of models to import in each INSERT statement.  This defaults to the size of the models array, i.e. only 1 INSERT statement.
```Crystal
models = [
  Model.new(id: 1, name: "Fred", age: 14),
  Model.new(id: 2, name: "Joe", age: 25),
  Model.new(id: 3, name: "John", age: 30),
  Model.new(id: 3, name: "Bill", age: 66),
]

Model.import(models, batch_size: 2)
# => First SQL INSERT statement imports Fred and Joe
# => Second SQL INSERT statement imports John and Bill
```

#### Running Callbacks

Since the `import` method runs on the class level, callbacks are not triggered automatically, they have to be triggered manually.  For example, using the Item class with a UUID primary key:
```Crystal
require "uuid"

class Item < Granite::Base
  adapter mysql
  table_name items

  primary item_id : String, auto: false
  field item_name : String

  before_create :generate_uuid

  def generate_uuid
    @item_id = UUID.random.to_s
  end
end  
```

```Crystal
items = [
  Item.new(item_name: "item1"),
  Item.new(item_name: "item2"),
  Item.new(item_name: "item3"),
  Item.new(item_name: "item4"),
]

# If we did `Item.import(items)` now, it would fail since the item_id wouldn't get set before saving the record, violating the primary key constraint.

# Manually run the callback on each model to generate the item_id.
items.each(&.before_create)

# Each model in the array now has a item_id set, so can be imported.
Item.import(items)

# This can also be used for a single record.
item = Item.new(item_name: "item5")
item.before_create
item.save
```

**Note:  Manually running your callbacks is mainly aimed at bulk imports.  Running them before a normal `.save`, for example, would run your callbacks twice.**

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

#### Find First

```crystal
post = Post.first
if post
  puts post.name
end

post = Post.first! # raises when no records exist
```

#### Find

```crystal
post = Post.find 1
if post
  puts post.name
end

post = Post.find! 1 # raises when no records found
```

#### Find By

```crystal
post = Post.find_by(slug: "example_slug")
if post
  puts post.name
end

post = Post.find_by!(slug: "foo") # raises when no records found.
other_post = Post.find_by(slug: "foo", type: "bar") # Also works for multiple arguments.
```

#### Create
```crystal
Post.create(name: "Granite Rocks!", body: "Check this out.") # Set attributes and call save
Post.create!(name: "Granite Rocks!", body: "Check this out.") # Set attributes and call save!. Will throw an exception when the save failed
```

#### Insert

```crystal
post = Post.new
post.name = "Granite Rocks!"
post.body = "Check this out."
post.save

post = Post.new
post.name = "Granite Rocks!"
post.body = "Check this out."
post.save! # raises when save failed
```

#### Update

```crystal
post = Post.find 1
post.name = "Granite Really Rocks!"
post.save

post = Post.find 1
post.update(name: "Granite Really Rocks!") # Assigns attributes and calls save

post = Post.find 1
post.update!(name: "Granite Really Rocks!") # Assigns attributes and calls save!. Will throw an exception when the save failed
```

#### Delete

```crystal
post = Post.find 1
post.destroy
puts "deleted" unless post

post = Post.find 1
post.destroy! # raises when delete failed
```

### Queries

The query macro and where clause combine to give you full control over your query.

#### All

When using the `all` method, the SQL selected fields will match the
fields specified in the model unless the `query` macro was used to customize
the SELECT.

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

#### First

It is common to only want the first result and append a `LIMIT 1` to the query.
This is what the `first` method does.

For example:

```crystal
post = Post.first("ORDER BY posts.name DESC")
```

This is the same as:

```crystal
post = Post.all("ORDER BY posts.name DESC LIMIT 1").first
```

#### Customizing SELECT

The `select_statement` macro allows you to customize the entire query, including the SELECT portion.  This shouldn't be necessary in most cases, but allows you to craft more complex (i.e. cross-table) queries if needed:

```crystal
class CustomView < Granite:Base
  adapter pg
  field articlebody : String
  field commentbody : String

  select_statement <<-SQL
    SELECT articles.articlebody, comments.commentbody
    FROM articles
    JOIN comments
    ON comments.articleid = articles.id
  SQL
end
```

You can combine this with an argument to `all` or `first` for maximum flexibility:

```crystal
results = CustomView.all("WHERE articles.author = ?", ["Noah"])
```

### Relationships

#### One to Many

`belongs_to` and `has_many` macros provide a rails like mapping between Objects.

```crystal
class User < Granite::Base
  adapter mysql

  has_many :posts

  field email : String
  field name : String
  timestamps
end
```

This will add a `posts` instance method to the user which returns an array of posts.

```crystal
class Post < Granite::Base
  adapter mysql

  belongs_to :user

  field title : String
  timestamps
end
```

This will add a `user` and `user=` instance method to the post.

For example:

```crystal
user = User.find 1
user.posts.each do |post|
  puts post.title
end

post = Post.find 1
puts post.user

post.user = user
post.save
```

In this example, you will need to add a `user_id` and index to your posts table:

```mysql
CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  title VARCHAR,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE INDEX 'user_id_idx' ON posts (user_id);
```

#### Many to Many

Instead of using a hidden many-to-many table, Granite recommends always creating a model for your join tables.  For example, let's say you have many `users` that belong to many `rooms`. We recommend adding a new model called `participants` to represent the many-to-many relationship.

Then you can use the `belongs_to` and `has_many` relationships going both ways.

```crystal
class User < Granite::Base
  has_many :participants

  field name : String
end

class Participant < Granite::Base
  belongs_to :user
  belongs_to :room
end

class Room < Granite::Base
  has_many :participants

  field name : String
end
```

The Participant class represents the many-to-many relationship between the Users and Rooms.

Here is what the database table would look like:

```mysql
CREATE TABLE participants (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  room_id BIGINT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE INDEX 'user_id_idx' ON TABLE participants (user_id);
CREATE INDEX 'room_id_idx' ON TABLE participants (room_id);
```

##### has_many through:

As a convenience, we provide a `through:` clause to simplify accessing the many-to-many relationship:

```crystal
class User < Granite::Base
  has_many :participants
  has_many :rooms, through: participants

  field name : String
end

class Participant < Granite::Base
  belongs_to :user
  belongs_to :room
end

class Room < Granite::Base
  has_many :participants
  has_many :users, through: participants

  field name : String
end
```

This will allow you to find all the rooms that a user is in:

```crystal
user = User.first
user.rooms.each do |room|
  puts room.name
end
```

And the reverse, all the users in a room:

```crystal
room = Room.first
room.users.each do |user|
  puts user.name
end
```

### Errors

All database errors are added to the `errors` array used by Granite::Validators with the symbol ':base'

```crystal
post = Post.new
post.save
post.errors[0].to_s.should eq "ERROR: name cannot be null"
```

### Callbacks

There is support for callbacks on certain events.

Here is an example:

```crystal
require "granite/adapter/pg"

class Post < Granite::Base
  adapter pg

  before_save :upcase_title

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

### Validation

Validations can be made on models to ensure that given criteria are met.

Models that do not pass the validations will not be saved, and will have the errors added to the model's `errors` array.

For example, asserting that the title on a post is not blank:

```Crystal
class Post < Granite::Base
  adapter mysql

  field title : String

  validate :title, "can't be blank" do |post|
    !post.title.to_s.blank?
  end
end
```

#### Validation Helpers

A set of common validation macros exist to make validations easier to manage/create.

**Common**
- `validate_not_nil :field` - Validates that field should not be nil.
- `validate_is_nil :field` - Validates that field should be nil.
- `validate_is_valid_choice :type, ["allowedType1", "allowedType2"]` - Validates that type should be one of a preset option.
- `validate_uniqueness :field` - Validates that the field is unique

**String**
- `validate_not_blank :field` - Validates that field should not be blank.
- `validate_is_blank :field` - Validates that field should be blank.
- `validate_min_length :field, 5` - Validates that field should be at least 5 long
- `validate_max_length :field, 20` - Validates that field should be at most 20 long

**Number**
- `validate_greater_than :field, 0` - Validates that field should be greater than 0.
- `validate_greater_than :field, 0, true` - Validates that field should be greater than or equal to 0.
- `validate_less_than :field, 100` - Validates that field should be less than 100.
- `validate_less_than :field, 100, true` - Validates that field should be less than or equal to 100.

Using the helpers, the previous example could have been written like:

```Crystal
class Post < Granite::Base
  adapter mysql

  field title : String

  validate_not_blank :title
end
```

### JSON Support

A few handy things that come from the `JSON::Serializable` support.  See [JSON::Serializable Docs](https://crystal-lang.org/api/0.25.1/JSON/Serializable.html) for more information.

#### JSON::Field

Allows for control over the serialization and deserialization of instance variables.  

```Crystal
class Foo < Granite::Base
  adapter mysql
  table_name foos

  field name : String
  field password : String, json_options: {ignore: true} # skip this field in serialization and deserialization
  field age : Int32, json_options: {key: "HowOldTheyAre"} # the value of the key in the json object 
  field todayBirthday : Bool, json_options: {emit_null: true} # emits a null value for nilable property
  field isNil : Bool
end
```

`foo = Foo.from_json(%({"name": "Granite1", "HowOldTheyAre": 12, "password": "12345"}))`

```Crystal
#<Foo:0x1e5df00
 @_current_callback=nil,
 @age=12,
 @created_at=nil,
 @destroyed=false,
 @errors=[],
 @id=nil,
 @isNil=nil,
 @name="Granite1",
 @new_record=true,
 @password=nil,
 @todayBirthday=nil,
 @updated_at=nil>
```

`foo.to_json`

```JSON
{
  "name":"Granite1",
  "HowOldTheyAre":12,
  "todayBirthday":null
}
```

Notice how `isNil` is omitted from the JSON output since it is Nil.  If you wish to always show Nil instance variables on a class level you can do:

```Crystal
@[JSON::Serializable::Options(emit_nulls: true)]
class Foo < Granite::Base
  adapter mysql
  table_name foos

  field name : String
  field age : Int32
end
```

This would be functionally the same as adding `json_options: {emit_null: true}` on each property.

#### after_initialize

This method gets called after `from_json` is done parsing the given JSON string. This allows you to set other fields that are not in the JSON directly or that require some more logic.

```Crystal
class Foo < Granite::Base
  adapter mysql
  table_name foos

  field name : String
  field age : Int32
  field date_added : Time

  def after_initialize
    @date_added = Time.utc_now
  end
end
```

`foo = Foo.from_json(%({"name": "Granite1"}))`

```Crystal
<Foo:0x55c77d901ea0
 @_current_callback=nil,
 @age=0,
 @created_at=nil,
 @destroyed=false,
 @date_added=2018-07-17 01:08:28.239807000 UTC,
 @errors=[],
 @id=nil,
 @name="Granite",
 @new_record=true,
 @updated_at=nil>
```

#### JSON::Serializable::Unmapped

If the JSON::Serializable::Unmapped module is included, unknown properties in the JSON document will be stored in a Hash(String, JSON::Any). On serialization, any keys inside `json_unmapped` will be serialized appended to the current JSON object.

```Crystal
class Foo < Granite::Base
  include JSON::Serializable::Unmapped

  adapter mysql
  table_name foos

  field name : String
  field age : Int32
end
```

`foo = Foo.from_json(%({"name": "Granite1", "age": 12, "foobar": true}))`

```Crystal
<Foo:0x55efba40ff00
 @_current_callback=nil,
 @age=12,
 @created_at=nil,
 @destroyed=false,
 @errors=[],
 @id=nil,
 @json_unmapped={"foobar" => true},
 @name="Granite1",
 @new_record=true,
 @updated_at=nil>
```

`foo.to_json`

```JSON
{
  "name": "Granite",
  "age": 12,
  "foobar": true
}
```

#### on_to_json

Allows doing additional manipulations before returning from `to_json`.

```Crystal
class Foo < Granite::Base
  adapter mysql
  table_name foos

  field name : String
  field age : Int32

  def on_to_json(json : JSON::Builder)
    json.field("years_young", @age)
  end
end
```

`foo = Foo.from_json(%({"name": "Granite1", "age": 12}))`

```Crystal
<Foo:0x55eb12bd2f00
 @_current_callback=nil,
 @age=12,
 @created_at=nil,
 @destroyed=false,
 @errors=[],
 @id=nil,
 @name="Granite1",
 @new_record=true,
 @updated_at=nil>
```

`foo.to_json`

```JSON
{
  "name": "Granite",
  "age": 12,
  "years_young": 12
}
```

### Migration

- `migrator` provides `drop`, `create` and `drop_and_create` methods

```crystal
class User < Granite::Base
  adapter mysql
  field name : String
end

User.migrator.drop_and_create
# => "DROP TABLE IF EXISTS `users`;"
# => "CREATE TABLE `users` (id BIGSERIAL PRIMARY KEY, name VARCHAR(255));"

User.migrator(table_options: "ENGINE=InnoDB DEFAULT CHARSET=utf8").create
# => "CREATE TABLE ... ENGINE=InnoDB DEFAULT CHARSET=utf8;"
```

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

After you have docker installed do the following to run tests:

#### First run

```
$ docker-compose build spec
$ docker-compose run spec
```

#### Subsequent runs

```
$ docker-compose run spec
```

#### Cleanup

If you're done testing and you'd like to shut down and clean up the docker dependences run the following:

```
$ docker-compose down
```

### Local setup

If you'd like to test without docker you can do so by following the instructions below:

1. Install dependencies with `$ crystal deps`
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
