# Adds a :nodoc: to granite methods/constants if `DISABLE_GRANTE_DOCS` ENV var is true
macro disable_granite_docs?(stmt)
  {% unless flag?(:granite_docs) %}
    # :nodoc:
    {{stmt.id}}
  {% else %}
    {{stmt.id}}
  {% end %}
end

module Granite::Tables
  module ClassMethods
    def adapter : Granite::Adapter::Base
      Granite::Connections.registered_connections.first? || raise "No connections have been registered."
    end

    def primary_name
      {% begin %}
      {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
      {% if pk = primary_key %}
        {{pk.name.stringify}}
      {% end %}
    {% end %}
    end

    def primary_type
      {% begin %}
      {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
      {% if pk = primary_key %}
        {{pk.type}}
      {% end %}
    {% end %}
    end

    def quoted_table_name : String
      adapter.quote(table_name)
    end

    def quote(column_name) : String
      adapter.quote(column_name)
    end

    # Returns the name of the table for `self`
    # defaults to the model's name underscored + 's'.
    def table_name : String
      {% begin %}
        {% table_ann = @type.annotation(Granite::Table) %}
        {{table_ann && !table_ann[:name].nil? ? table_ann[:name] : @type.name.underscore.stringify.split("::").last}}
      {% end %}
    end
  end

  macro table(name)
    @[Granite::Table(name: {{(name.is_a?(StringLiteral) ? name : name.id.stringify) || nil}})]
    class ::{{@type.name.id}}; end
  end

  # specify the database connection you will be using for this model.
  macro connection(name)
    class_getter adapter : Granite::Adapter::Base = Granite::Connections[{{(name.is_a?(StringLiteral) ? name : name.id.stringify)}}] || raise "No registered connection with the name '{{name.id}}'"
  end
end
