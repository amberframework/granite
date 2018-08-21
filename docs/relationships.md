# Relationships

## One to Many

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

## Many to Many

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

## has_many through:

As a convenience, we provide a `through:` clause to simplify accessing the many-to-many relationship:

```crystal
class User < Granite::Base
  has_many :participants
  has_many :rooms, through: :participants

  field name : String
end

class Participant < Granite::Base
  belongs_to :user
  belongs_to :room
end

class Room < Granite::Base
  has_many :participants
  has_many :users, through: :participants

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
