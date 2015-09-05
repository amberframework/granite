require "spec"
require "../src/amethyst-model"
include Amethyst::Model

class Post < Model
  adapter mysql
  fields({ name: "VARCHAR(255)", body: "TEXT" })
end

class PostsByMonth < RoModel
  adapter mysql
  fields({ month: "MONTHNAME(created_at)", 
           total: "COUNT(*)" 
         }, "posts")
end

class Comment < Model
  adapter sqlite
  fields({ name: "CHAR(255)", body: "TEXT" })
end

Post.drop
Post.create

Comment.drop
Comment.create
