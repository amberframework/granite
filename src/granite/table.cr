# Adds a :nodoc: to granite methods/constants if `DISABLE_GRANTE_DOCS` ENV var is true
macro noDoc(stmt)
  {% if env("DISABLE_GRANTE_DOCS") == "true" %}
    # :nodoc:
    {{stmt.id}}
  {% else %}
    {{stmt.id}}
  {% end %}
end

module Granite::Table
  macro included
    macro inherited
      noDoc SETTINGS = {} of Nil => Nil
      noDoc PRIMARY = {name: id, type: Int64, auto: true}
    end
  end

  # specify the database adapter you will be using for this model.
  # mysql, pg, sqlite, etc.
  macro adapter(name)
    @@adapter = Granite::Adapter::{{name.id.capitalize}}.new("{{name.id}}")

    noDoc def self.adapter
      @@adapter
    end
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
    {% table_name = SETTINGS[:table_name] || name_space + "s" %}
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}
    {% primary_auto = PRIMARY[:auto] %}

    @@table_name = "{{table_name}}"
    @@primary_name = "{{primary_name}}"
    @@primary_auto = "{{primary_auto}}"
    @@primary_type = "{{primary_type}}"

    noDoc def self.table_name
      @@table_name
    end

    noDoc def self.primary_name
      @@primary_name
    end

    noDoc def self.primary_type
      @@primary_type
    end

    noDoc def self.primary_auto
      @@primary_auto
    end

    noDoc def self.quoted_table_name
      @@adapter.quote(table_name)
    end

    noDoc def self.quote(column_name)
      @@adapter.quote(column_name)
    end
  end
end
