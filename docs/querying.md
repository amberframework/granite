# Querying

The query macro and where clause combine to give you full control over your query.

## Where

Where is using a QueryBuilder that allows you to chain where clauses together to build up a complete query.
```crystal
posts = Post.where(published: true, author_id: User.first!.id)
```

It supports different operators:
```crystal
Post.where(:created_at, :gt, Time.local - 7.days)
```

Supported operators are :eq, :gteq, :lteq, :neq, :gt, :lt, :nlt, :ngt, :ltgt, :in, :nin, :like, :nlike

Alternatively, `#where`, `#and`, and `#or` accept a raw SQL clause, with an optional placeholder (`?` for MySQL/SQLite, `$` for Postgres) to avoid SQL Injection.
```crystal
# Example using Postgres adapter
Post.where(:created_at, :gt, Time.local - 7.days)
  .where("LOWER(author_name) = $", name)
  .where("tags @> '{"Journal", "Book"}') # PG's array contains operator
```
This is useful for building more sophisticated queries, including queries dependent on database specific features not supported by the operators above. However, **clauses built with this method are not validated.**


## Order

Order is using the QueryBuilder and supports providing an ORDER BY clause:
```crystal
Post.order(:created_at)
```

Direction
```crystal
Post.order(updated_at: :desc)
```

Multiple fields
```crystal
Post.order([:created_at, :title])
```

With direction
```crystal
Post.order(created_at: :desc, title: :asc)
```

## Group By

Group is using the QueryBuilder and supports providing an GROUP BY clause:
```crystal
posts = Post.group_by(:published)
```

Multiple fields
```crystal
Post.group_by([:published, :author_id])
```

## Limit

Limit is using the QueryBuilder and provides the ability to limit the number of tuples returned:
```crystal
Post.limit(50)
```

## Offset

Offset is using the QueryBuilder and provides the ability to offset the results. This is used for pagination:
```crystal
Post.offset(100).limit(50)
```

## All

All is not using the QueryBuilder.  It allows you to directly query the database using SQL.

When using the `all` method, the selected fields will match the
fields specified in the model unless the `select` macro was used to customize
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

## Customizing SELECT

The `select_statement` macro allows you to customize the entire query, including the SELECT portion.  This shouldn't be necessary in most cases, but allows you to craft more complex (i.e. cross-table) queries if needed:

```crystal
class CustomView < Granite:Base
  connection pg

  column id : Int64, primary: true
  column articlebody : String
  column commentbody : String

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

## Exists?

The `exists?` class method returns `true` if a record exists in the table that matches the provided *id* or *criteria*, otherwise `false`.

If passed a `Number` or `String`, it will attempt to find a record with that primary key.  If passed a `Hash` or `NamedTuple`, it will find the record that matches that criteria, similar to `find_by`.

```crystal
# Assume a model named Post with a title field
post = Post.new(title: "My Post")
post.save
post.id # => 1

Post.exists? 1 # => true
Post.exists? {"id" => 1, :title => "My Post"} # => true
Post.exists? {id: 1, title: "Some Post"} # => false
```

The `exists?` method can also be used with the query builder.

```crystal
Post.where(published: true, author_id: User.first!.id).exists?
Post.where(:created_at, :gt, Time.local - 7.days).exists?
```
