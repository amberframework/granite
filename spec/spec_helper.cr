require "spec"
require "../src/amethyst-model"
include Amethyst::Model

class Post < Model
  adapter mysql
  sql_mapping({ name: "VARCHAR(255)", 
                body: "TEXT" })
end

class PostsByMonth < RoModel
  adapter mysql
  sql_mapping({ month: "MONTHNAME(created_at)", 
                total: "COUNT(*)" 
              }, "posts")
end

class Comment < Model
  adapter sqlite 
  sql_mapping({ name: "CHAR(255)", 
                body: "TEXT" })
end

class User < Model
  adapter postgresql 
  sql_mapping({ name: "VARCHAR(20)", 
                pass: "VARCHAR(20)" })
end

Post.drop
Post.create

Comment.drop
Comment.create

User.drop
User.create
