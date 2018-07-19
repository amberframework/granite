# Querying

The query macro and where clause combine to give you full control over your query.

## All

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

## First

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

## Customizing SELECT

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

## 