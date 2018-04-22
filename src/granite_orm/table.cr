module Granite::ORM::Table
  macro included
    macro inherited
      SETTINGS = {} of Nil => Nil
      PRIMARY = {name: id, type: Int64, auto: true}
    end
  end

  # specify the database adapter you will be using for this model.
  # mysql, pg, sqlite, etc.
  macro adapter(name)
    @@adapter = Granite::Adapter::{{name.id.capitalize}}.new("{{name.id}}")

    def self.adapter
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

  # specify the primary key column and type and auto_increment
  macro primary(decl, auto)
    {% PRIMARY[:name] = decl.var %}
    {% PRIMARY[:type] = decl.type %}
    {% PRIMARY[:auto] = auto %}
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

    def self.table_name
      @@table_name
    end

    def self.primary_name
      @@primary_name
    end

    def self.primary_auto
      @@primary_auto
    end

    def self.quoted_table_name
      @@adapter.quote(table_name)
    end

    def self.quote(column_name)
      @@adapter.quote(column_name)
    end
  end
end
