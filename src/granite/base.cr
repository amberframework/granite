require "./collection"
require "./association_collection"
require "./associations"
require "./callbacks"
require "./columns"
require "./query/executors/base"
require "./query/**"
require "./settings"
require "./table"
require "./validators"
require "./validation_helpers/**"
require "./migrator"
require "./select"
require "./version"
require "./connections"
require "./integrators"
require "./converters"
require "./type"

# Granite::Base is the base class for your model objects.
abstract class Granite::Base
  include Associations
  include Callbacks
  include Columns
  include Tables
  include Transactions
  include Validators
  include ValidationHelpers
  include Migrator
  include Select

  extend Columns::ClassMethods
  extend Tables::ClassMethods
  extend Granite::Migrator::ClassMethods

  extend Querying
  extend Query::BuilderMethods
  extend Transactions::ClassMethods
  extend Integrators
  extend Select

  macro inherited
    @@select = Container.new(table_name: table_name, fields: fields)

    # Returns true if this object hasn't been saved yet.
    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    disable_granite_docs? property? new_record : Bool = true

    # Returns true if this object has been destroyed.
    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    disable_granite_docs? getter? destroyed : Bool = false

    # Returns true if the record is persisted.
    disable_granite_docs? def persisted?
      !(new_record? || destroyed?)
    end

  # Consumes the result set to set self's property values.
  disable_granite_docs? def initialize(result : DB::ResultSet) : Nil
    {% verbatim do %}
      {% begin %}
        {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
          {% ann = column.annotation(Granite::Column) %}
          @{{column.id}} = {% if ann[:converter] %} {{ann[:converter]}}.from_rs result {% else %} Granite::Type.from_rs(result, {{column.type}}) {% end %}
        {% end %}
      {% end %}
    {% end %}
  end

    disable_granite_docs? def initialize(*args, **named_args)
      {% verbatim do %}
        {% begin %}
          {% for column, idx in @type.instance_vars.select { |ivar| (ann = ivar.annotation(Granite::Column)) && (!ann[:primary] || (ann[:primary] && ann[:auto] == false)) } %}
            @{{column.id}} = if (val = args[{{idx}}]?) || (val = named_args[{{column.name.stringify}}]?)
              val
            else
              {% if column.has_default_value? %}
                {{column.default_value}}
              {% elsif !column.type.nilable? %}
                raise "Missing required property {{column}}"
              {% else %}
                nil
              {% end %}
            end
          {% end %}
        {% end %}
      {% end %}
    end
  end
end
