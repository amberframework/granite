# Relationships

## One to One

For one-to-one relationships, You can use the `has_one` and `belongs_to` in your models.

> **Note:** one-to-one relationship does not support through associations yet.

```crystal
class Team < Granite::Base
  has_one :coach

  column id : Int64, primary: true
  column name : String
end
```

This will add a `coach` and `coach=` instance methods to the team which returns associated coach.

```crystal
class Coach < Granite::Base
  table coaches

  belongs_to :team

  column id : Int64, primary: true
  column name : String
end
```

This will add a `team` and `team=` instance method to the coach.

For example:

```crystal
team = Team.find! 1
# has_one side..
puts team.coach

coach = Coach.find! 1
# belongs_to side...
puts coach.team

coach.team = team
coach.save

# or in one-to-one you can also do

team.coach = coach
# coach is the child entity and contians the foreign_key
# so save should called on coach instance
coach.save

```

In this example, you will need to add a `team_id` and index to your coaches table:

```sql
CREATE TABLE coaches (
  id BIGSERIAL PRIMARY KEY,
  team_id BIGINT,
  name VARCHAR,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE INDEX team_id_idx ON coaches (team_id);
```

Foreign key is inferred from the class name of the Model which uses `has_one`. In above case `team_id` is assumed to be present in `coaches` table. In case its different you can specify one like this:

```crystal
class Team < Granite::Base
  has_one :coach, foreign_key: :custom_id

  column id : Int64, primary: true
  column name : String
end

class Coach < Granite::Base
  belongs_to :team
  
  column id : Int64, primary: true
end
```

The class name inferred from the name but you can specify the class name:
```crystal
class Team < Granite::Base
  has_one coach : Coach, foreign_key: :custom_id

  # or you can provide the class name as a parameter
  has_one :coach, class_name: Coach, foreign_key: :custom_id

  column id : Int64, primary: true
  column name : String
end

class Coach < Granite::Base
  belongs_to team : Team

  # provide a custom foreign key
  belongs_to team : Team, foreign_key: team_uuid : String
  
  column id : Int64, primary: true
end
```

## One to Many

`belongs_to` and `has_many` macros provide a rails like mapping between Objects.

```crystal
class User < Granite::Base
  connection mysql

  has_many :post

  # pluralization requires providing the class name
  has_many posts : Post

  # or you can provide class name as a parameter
  has_many :posts, class_name: Post

  # you can provide a custom foreign key
  has_many :posts, class_name: Post, foreign_key: :custom_id

  column id : Int64, primary: true
  column name : String
  column email : String
  timestamps
end
```

This will add a `posts` instance method to the user which returns an array of posts.

```crystal
class Post < Granite::Base
  connection mysql
  table posts

  belongs_to :user

  # or custom name
  belongs_to my_user : User

  # or custom foreign key
  belongs_to user : User, foreign_key: uuid : String

  column id : Int64, primary: true
  column title : String
  timestamps
end
```

This will add a `user` and `user=` instance method to the post.

For example:

```crystal
user = User.find! 1
user.posts.each do |post|
  puts post.title
end

post = Post.find! 1
puts post.user

post.user = user
post.save
```

In this example, you will need to add a `user_id` and index to your posts table:

```sql
CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  title VARCHAR,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE INDEX user_id_idx ON posts (user_id);
```

## Many to Many

Instead of using a hidden many-to-many table, Granite recommends always creating a model for your join tables.  For example, let's say you have many `users` that belong to many `rooms`. We recommend adding a new model called `participants` to represent the many-to-many relationship.

Then you can use the `belongs_to` and `has_many` relationships going both ways.

```crystal
class User < Granite::Base
  has_many :participants, class_name: Participant

  column id : Int64, primary: true
  column name : String
end

class Participant < Granite::Base
  table participants

  belongs_to :user
  belongs_to :room
  
  column id : Int64, primary: true
end

class Room < Granite::Base
  table rooms

  has_many :participants, class_name: Participant

  column id : Int64, primary: true
  column name : String
end
```

The Participant class represents the many-to-many relationship between the Users and Rooms.

Here is what the database table would look like:

```sql
CREATE TABLE participants (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT,
  room_id BIGINT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE INDEX user_id_idx ON TABLE participants (user_id);
CREATE INDEX room_id_idx ON TABLE participants (room_id);
```

## has_many through:

As a convenience, we provide a `through:` clause to simplify accessing the many-to-many relationship:

```crystal
class User < Granite::Base
  has_many :participants, class_name: Participant
  has_many :rooms, class_name: Room, through: :participants

  column id : Int64, primary: true
  column name : String
end

class Participant < Granite::Base
  belongs_to :user
  belongs_to :room
  
  column id : Int64, primary: true
end

class Room < Granite::Base
  has_many :participants, class_name: Participant
  has_many :users, class_name: User, through: :participants

  column id : Int64, primary: true
  column name : String
end
```

This will allow you to find all the rooms that a user is in:

```crystal
user = User.create(name: "Bob")
room = Room.create(name: "#crystal-lang")
room2 = Room.create(name: "#amber")
Participant.create(user_id: user.id, room_id: room.id)
Participant.create(user_id: user.id, room_id: room2.id)

user.rooms.each do |room|
  puts room.name
end
```

And the reverse, all the users in a room:

```crystal
room.users.each do |user|
  puts user.name
end
```
