# CRUD

## Create

Combination of object creation and insertion into database.

```
Post.create(name: "Granite Rocks!", body: "Check this out.") # Set attributes and call save
Post.create!(name: "Granite Rocks!", body: "Check this out.") # Set attributes and call save!. Will throw an exception when the save failed
```

## Insert

Inserts an already created object into the database.

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

## Read

### find

Finds the record with the given primary key.

```crystal
post = Post.find 1
if post
  puts post.name
end

post = Post.find! 1 # raises when no records found
```
### find_by

Finds the record(s) that match the given criteria

```crystal
post = Post.find_by(slug: "example_slug")
if post
  puts post.name
end

post = Post.find_by!(slug: "foo") # raises when no records found.
other_post = Post.find_by(slug: "foo", type: "bar") # Also works for multiple arguments.
```
### first

Returns the first record.

```crystal
post = Post.first
if post
  puts post.name
end

post = Post.first! # raises when no records exist
```
### all

Returns all records of a model.

```crystal
posts = Post.all
if posts
  posts.each do |post|
    puts post.name
  end
end
```


## Update

Updates a given record already saved in the database.

```crystal
post = Post.find 1
post.name = "Granite Really Rocks!"
post.save

post = Post.find 1
post.update(name: "Granite Really Rocks!") # Assigns attributes and calls save

post = Post.find 1
post.update!(name: "Granite Really Rocks!") # Assigns attributes and calls save!. Will throw an exception when the save failed
```
## Delete

Delete a specific record.

```crystal
post = Post.find 1
post.destroy
puts "deleted" unless post

post = Post.find 1
post.destroy! # raises when delete failed
```
Clear all records of a model

```crystal
Post.clear #truncate the table
```