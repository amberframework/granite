module Granite::ORM::Table
  macro included
    macro inherited
      SETTINGS = {} of Nil => Nil
      PRIMARY = {name: id, type: Int64}
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

  macro __process_table
    {% name_space = @type.name.gsub(/::/, "_").underscore.id %}
    {% table_name = SETTINGS[:table_name] || name_space + "s" %}
    {% primary_name = PRIMARY[:name] %}
    {% primary_type = PRIMARY[:type] %}

    @@table_name = "{{table_name}}"
    @@primary_name = "{{primary_name}}"

    property? {{primary_name}} : Union({{primary_type.id}} | Nil)

    def {{primary_name}}
      raise {{@type.name.stringify}} + "#" + {{primary_name.stringify}} + " cannot be nil" if @{{primary_name}}.nil?
      @{{primary_name}}.not_nil!
    end

    def self.table_name
      @@table_name
    end

    def self.primary_name
      @@primary_name
    end

    def self.quoted_table_name
      @@adapter.quote(table_name)
    end

    def self.quote(column_name)
      @@adapter.quote(column_name)
    end
  end
end
