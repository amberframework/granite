require "./error"

# DB migration tool that prepares a table for the class
#
# ```crystal
# class User < Granite::Base
#   adapter mysql
#   field name : String
# end
#
# User.migrator.drop_and_create
# # => "DROP TABLE IF EXISTS `users`;"
# # => "CREATE TABLE `users` (id BIGSERIAL PRIMARY KEY, name VARCHAR(255));"
#
# User.migrator(table_options: "ENGINE=InnoDB DEFAULT CHARSET=utf8").create
# # => "CREATE TABLE ... ENGINE=InnoDB DEFAULT CHARSET=utf8;"
# ```
module Granite::Migrator
  module ClassMethods
    def migrator(**args)
      Migrator(self).new(**args)
    end
  end

  class Migrator(Model)
    def initialize(@table_options = "")
    end

    def drop_and_create
      drop
      create
    end

    def drop_sql
      "DROP TABLE IF EXISTS #{Model.quoted_table_name};"
    end

    def drop
      Model.exec drop_sql
    end

    def create_sql
      resolve = ->(key : String) {
        Model.adapter.class.schema_type?(key) || raise "Migrator(#{Model.adapter.class.name}) doesn't support '#{key}' yet."
      }

      String.build do |s|
        s.puts "CREATE TABLE #{Model.quoted_table_name}("

        # primary key
        {% begin %}
          {% primary_key = Model.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
          {% raise raise "A primary key must be defined for #{Model.name}." unless primary_key %}
          {% ann = primary_key.annotation(Granite::Column) %}
          k = Model.adapter.quote("{{primary_key.name}}")
          v =
            {% if ann[:auto] %}
              resolve.call("AUTO_{{primary_key.type.union_types.find { |t| t != Nil }.id}}")
            {% else %}
              resolve.call("{{ivar.type.union_types.find { |t| t != Nil }.id}}")
            {% end %}
          s.print "#{k} #{v} PRIMARY KEY"
        {% end %}

        # content fields
        {% for ivar in Model.instance_vars.select { |ivar| (ann = ivar.annotation(Granite::Column)) && !ann[:primary] } %}
          {% ann = ivar.annotation(Granite::Column) %}
          s.puts ","
          k = Model.adapter.quote("{{ivar.name}}")
          v =
            {% if ann[:column_type] %}
              "{{ann[:column_type].id}}"
            {% elsif ivar.name.id == "created_at" || ivar.name.id == "updated_at" %}
              resolve.call("{{ivar.name}}")
            {% elsif ann[:nilable] %}
              resolve.call("{{ivar.type.union_types.find { |t| t != Nil }.id}}")
            {% else %}
              resolve.call("{{ivar.type.union_types.find { |t| t != Nil }.id}}") + " NOT NULL"
            {% end %}
          s.puts "#{k} #{v}"
        {% end %}

        s.puts ") #{@table_options};"
      end
    end

    def create
      Model.exec create_sql
    end
  end
end
