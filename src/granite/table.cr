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
  macro included
    macro inherited
      disable_granite_docs? SETTINGS = {} of Nil => Nil
      disable_granite_docs? PRIMARY = {name: id, type: Int64, auto: true}
    end
  end

  # specify the database adapter you will be using for this model.
  # mysql, pg, sqlite, etc.
  macro adapter(name)
    class_getter adapter : Granite::Adapter::Base = Granite::Adapters.registered_adapters.find { |adapter| adapter.name == {{name.stringify}} } || raise "No registered adapter with the name '{{name.id}}'"
  end

  # specify the table name to use otherwise it will use the model's name
  macro table_name(name)
    {% SETTINGS[:table_name] = name.id %}
  end

  # specify the primary key column and type
  macro primary(decl)
    {% PRIMARY[:name] = decl.var %}
    {% PRIMARY[:type] = decl.type %}
  end

  # specify the primary key column and type and comment
  macro primary(decl, comment)
    {% PRIMARY[:name] = decl.var %}
    {% PRIMARY[:type] = decl.type %}
    {% PRIMARY[:comment] = comment %}
  end

  # specify the primary key column and type and auto_increment
  macro primary(decl, auto)
    {% PRIMARY[:name] = decl.var %}
    {% PRIMARY[:type] = decl.type %}
    {% PRIMARY[:auto] = auto %}
  end

  # specify the primary key column and type and auto_increment and comment
  macro primary(decl, comment, auto)
    {% PRIMARY[:name] = decl.var %}
    {% PRIMARY[:type] = decl.type %}
    {% PRIMARY[:auto] = auto %}
    {% PRIMARY[:comment] = comment %}
  end

  macro __process_table
    {% name_space = @type.name.gsub(/::/, "_").underscore.id %}
    {% table_name = SETTINGS[:table_name] || name_space %}
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    {% primary_auto = PRIMARY[:auto] %}

    @@table_name = "{{table_name}}"
    @@primary_name = "{{primary_name}}"
    @@primary_auto = "{{primary_auto}}"
    @@primary_type = "{{primary_type}}"

    disable_granite_docs? def self.table_name
      @@table_name
    end

    disable_granite_docs? def self.primary_name
      @@primary_name
    end

    disable_granite_docs? def self.primary_type
      @@primary_type
    end

    disable_granite_docs? def self.primary_auto
      @@primary_auto
    end

    disable_granite_docs? def self.quoted_table_name
      @@adapter.quote(table_name)
    end

    disable_granite_docs? def self.quote(column_name)
      @@adapter.quote(column_name)
    end
  end
end
