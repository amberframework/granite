# amethyst-model

[Amethyst](https://github.com/Codcore/amethyst) is a web framework written in the [Crystal](https://github.com/manastech/crystal) language. 

This project is to provide a mysql ORM Base::Model that provides simple
database usage.

## Installation

Add this library to your Amethyst dependencies in your Projectfile.

```crystal
deps do
  # Amethyst Framework
  github "Codcore/amethyst"
  github "spalger/crystal-mime"

  # Amethyst Model
  github "drujensen/amethyst-model"
end
```

Next you will need to create a `config/database.yml`

```yaml
development: 
  database: blog_development
  host: 127.0.0.1
  port: 3306
  username: root
  password: 

test: 
  database: blog_test
  host: 127.0.0.1
  port: 3306
  username: root
  password: 

```

## Usage

Here is classic 'Post' using Amethyst Model
```crystal
require "amethyst-model"
include Amethyst::Model

class Post < Base::Model
  fields({ name: "VARCHAR(255)", body: "TEXT" })

  # properties id, name, body, created_at, updated_at are generated for you

end

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

### Clause

Clause will give you full control over your query. Instead of building another
DSL to build the query, we decided to use good ole SQL.

The table is namespaced with `_t` so you can perform joins without conflicting
field names.

Its important to realize that the selected fields will always match the fields 
specified in the model.

Always pass in parameters to avoid SQL Injection.  Use `:{field}` for
parameter replacements.

```crystal
posts = Post.clause("WHERE name LIKE :name", {"name" => "Test%"})
if posts
  posts.each do |post|
    puts post.name
  end
end

# ORDER BY Example
posts = Post.clause("ORDER BY created_at DESC")

# JOIN Example
posts = Post.clause(", comments c WHERE c.post_id = _t.id AND c.name = :name ORDER BY created_at DESC", {"name" => "Dru Jensen"})

```
## RoadMap
- ReadOnly Base Model that can handle complex query results
- Connection Pool
- has_many, belongs_to support

## Contributing

1. Fork it ( https://github.com/drujensen/amethyst-model/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [drujensen](https://github.com/drujensen) drujensen - creator, maintainer
