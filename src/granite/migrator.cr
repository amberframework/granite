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
  class Base
    @quoted_table_name : String

    def initialize(klass, @table_options = "")
      @quoted_table_name = klass.quoted_table_name
    end

    def drop_and_create
      drop
      create
    end

    def drop
    end

    def create
    end
  end

  macro __process_migrator
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    {% primary_auto = PRIMARY[:auto] %}
    {% klass = @type.name %}
    {% adapter = "#{klass}.adapter".id %}

    disable_granite_docs? class Migrator < Granite::Migrator::Base
      def drop
        {{klass}}.exec "DROP TABLE IF EXISTS #{ @quoted_table_name };"
      end

      def create
        resolve = ->(key : String) {
          {{adapter}}.class.schema_type?(key) || raise "Migrator(#{ {{adapter}}.class.name }) doesn't support '#{key}' yet."
        }

        stmt = String.build do |s|
          s.puts "CREATE TABLE #{ @quoted_table_name }("

          # primary key
          k = {{adapter}}.quote("{{primary_name}}")
          v =
            {% if primary_auto %}
              resolve.call("AUTO_{{primary_type.id}}")
            {% else %}
              resolve.call("{{primary_type.id}}")
            {% end %}
          s.print "#{k} #{v} PRIMARY KEY"

          # content fields
          {% for name, options in CONTENT_FIELDS %}
            s.puts ","
            k = {{adapter}}.quote("{{name}}")
            v =
              {% if name.id == "created_at" || name.id == "updated_at" %}
                resolve.call("{{name}}")
              {% else %}
                resolve.call("{{options[:type]}}")
              {% end %}
            s.puts "#{k} #{v}"
          {% end %}

          s.puts ") #{@table_options};"
        end

        {{klass}}.exec stmt
      end
    end

    disable_granite_docs? def self.migrator(**args)
      Migrator.new(self, **args)
    end
  end
end
