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

    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    # Returns true if this object hasn't been saved yet.
    disable_granite_docs? property? new_record : Bool = true

    @[JSON::Field(ignore: true)]
    @[YAML::Field(ignore: true)]
    # Returns true if this object has been destroyed.
    disable_granite_docs? getter? destroyed : Bool = false

    # Returns true if the record is persisted.
    disable_granite_docs? def persisted?
      !(new_record? || destroyed?)
    end

    # Consumes the result set to set self's property values.
    disable_granite_docs? def initialize(result : DB::ResultSet) : Nil
      {% verbatim do %}
        {% begin %}
          result.column_names.each do |col|
            case col
            {% for column in @type.instance_vars.select { |ivar| ivar.annotation(Granite::Column) } %}
              {% ann = column.annotation(Granite::Column) %}
              when {{column.name.stringify}} then @{{column.id}} = {% if ann[:converter] %} {{ann[:converter]}}.from_rs result {% else %} Granite::Type.from_rs(result, {{column.type}}) {% end %}
            {% end %}
            end
          end
        {% end %}
      {% end %}
    end

    def initialize; end
  end
end
