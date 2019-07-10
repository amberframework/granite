# Adds a :nodoc: to granite methods/constants if `DISABLE_GRANTE_DOCS` ENV var is true
macro disable_granite_docs?(stmt)
  {% unless env("DISABLE_GRANITE_DOCS") == "false" %}
    # :nodoc:
    {{stmt.id}}
  {% else %}
    {{stmt.id}}
  {% end %}
end

module Granite::Table
  module ClassMethods
    def primary_name : String?
      {% begin %}
      {% primary_key = @type.instance_vars.find { |ivar| (ann = ivar.annotation(Granite::Column)) && ann[:primary] } %}
      {% if pk = primary_key %}
        {{pk.name.stringify}}
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
        {% table_ann = @type.annotation(Granite::Model) %}
        {{table_ann && !table_ann[:table].nil? ? table_ann[:table] : @type.name.underscore.stringify}}
      {% end %}
    end
  end

  macro table(name)
    @[Granite::Model(table: {{(name.is_a?(StringLiteral) ? name : name.stringify) || nil}})]
    class ::{{@type.name.id}}; end
  end

  # specify the database adapter you will be using for this model.
  # mysql, pg, sqlite, etc.
  macro adapter(name)
    class_getter adapter : Granite::Adapter::Base = Granite::Adapters.registered_adapters.find { |adapter| adapter.name == {{name.stringify}} } || raise "No registered adapter with the name '{{name.id}}'"
  end
end
