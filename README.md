# amethyst-model

[![Build Status](https://travis-ci.org/drujensen/amethyst-model.svg)](https://travis-ci.org/drujensen/amethyst-model)

[![docrystal.org](http://www.docrystal.org/badge.svg)](http://www.docrystal.org/github.com/drujensen/amethyst-model)

[Amethyst](https://github.com/Codcore/amethyst) is a web framework written in
the [Crystal](https://github.com/manastech/crystal) language. 

This project is to provide an ORM Model for Amethyst using the
[waterlink/crystal-mysql](https://github.com/waterlink/crystal-mysql) driver.

## Installation

Add this library to your Amethyst dependencies along with the MySQL driver in
your Projectfile.

```crystal
deps do
  # Amethyst Framework
  github "Codcore/amethyst"
  github "spalger/crystal-mime"

  # Amethyst Model
  github "drujensen/amethyst-model"
  github "waterlink/crystal-mysql"
end
```

Next you will need to create a `config/database.yml`

```yaml
development: 
  database: blog_development
  host: 127.0.0.1
  port: 3306
  username: root
  password: ${DB_PASSWORD}

test: 
  database: blog_test
  host: 127.0.0.1
  port: 3306
  username: root
  password: ${DB_PASSWORD} 

```

You can leverage environment variables using ${} syntax.

## Usage

Here is classic 'Post' using Amethyst Model

```crystal
require "amethyst-model"
include Amethyst::Model

class Post < Model
  fields({ name: "VARCHAR(255)", body: "TEXT" })
  # properties id, name, body, created_at, updated_at are created for you
  # table name is posts

  # fields({ name: "VARCHAR(255)", body: "TEXT" }, "blog", false)
  # custom table name and disable timestamps
  # properties id, name, body
  # table name is blog

end

```
### Fields

To define the fields for this model, you need to provide a hash with the name
of the field as a `Symbol` and the MySQL type as a `String`.  This can include
any other options that MySQL provides to you.  

3 Fields are automatically created for you:  id, created_at, updated_at.
These will also be set for you when you use the `save` method.

MySQL field definitions for id, created_at, updated_at

```mysql
  id INT NOT NULL AUTO_INCREMENT
  # Your fields go here
  created_at DATE
  updated_at DATE 
  PRIMARY KEY (id)
```

### DDL Built in

```crystal
Post.drop #drop the table

Post.create #create the table

Post.clear #truncate the table
```

### DML

#### Find All

```crystal
posts = Post.all
if posts
  posts.each do |post|
    puts post.name
  end
end
```

#### Find One

```crystal
post = Post.find 1
if post
  puts post.name
end
```

#### Insert

```crystal
post = Post.new
post.name = "Amethyst Rocks!"
post.body = "Check this out."
post.save
```

#### Update

```crystal
post = Post.find 1
post.name = "Amethyst Really Rocks!"
post.save
```

#### Delete

```crystal
post = Post.find 1
post.destroy
puts "deleted" unless post
```

### Where 

The where clause will give you full control over your query. Instead of
building another DSL to build the query, we decided to use good ole SQL.

When using the `all` method, the SQL selected fields will always match the
fields specified in the model.  If you need different fields, consider
creating a new model.

Always pass in parameters to avoid SQL Injection.  Use a symbol in your query
i.e. `:param` for parameter replacement.  Check out
[waterlink/crystal-mysql](https://github.com/waterlink/crystal-mysql) for more
details.

The table is namespaced with the name of the class so you can perform joins
without conflicting field names.

```crystal
posts = Post.all("WHERE name LIKE :name", {"name" => "Joe%"})
if posts
  posts.each do |post|
    puts post.name
  end
end

# ORDER BY Example
posts = Post.all("ORDER BY created_at DESC")

# JOIN Example
posts = Post.all("JOIN comments c ON c.post_id = post.id 
                  WHERE c.name = :name 
                  ORDER BY post.created_at DESC", 
                  {"name" => "Joe"})

```
### Read Only Model

A Read Only Model allows you to perform queries against the database that
cannot be updated.  The results will be mapped to fields in this model.

```crystal
class PostsByMonth < RoModel
  fields({ month: "MONTHNAME(created_at)", total: "COUNT(*)" }, "posts")
end

posts_by_month = PostsByMonth.all("GROUP BY MONTH(created_at)")
```

The fields mapping is a little different than regular models.  Instead of the
field type, you will use the calculated expression used in a `SELECT` statement.  The table name is required.

## RoadMap
- Connection Pool
- Expose the connection to support transactions
- has_many, belongs_to support

## Contributing

1. Fork it ( https://github.com/drujensen/amethyst-model/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [drujensen](https://github.com/drujensen) drujensen - creator, maintainer
