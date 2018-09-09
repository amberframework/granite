# Adds equals, hash, and comparison methods to Granite::Base objects.
module Granite::Comparator
  macro __process_comparator

    def_equals_and_hash {{ *FIELDS.keys }}

    {%
      pk_type = PRIMARY[:type].id
      pk_type_node = PRIMARY[:type].resolve
      pk_field = PRIMARY[:name].id
    %}

    {% if pk_type_node.has_method?("<=>") %}
    # Compares this `{{@type}}` to another `{{@type}}` by comparing their primary keys (`{{pk_field}}`).
    #
    # Returns 0 if the two primary keys are equal, a negative number if this object's primary key is considered less than other's, or a positive number otherwise.
    {% else %}
    # Raises an exception; the `{{pk_field}}` field does not implement the `<=>` operator.
    {% end %}
    def <=>(other : {{@type}})
      raise "Cannot compare two {{@type}} objects if either's `{{pk_field}}` is `nil`." if self.{{pk_field}}.nil? || other.{{pk_field}}.nil?
      {% if pk_type_node.has_method?("<=>") %}
        self.{{pk_field}}.as({{pk_type}}) <=> other.{{pk_field}}.as({{pk_type}})
      {% else %}
        raise "Cannot compare two {{@type}} objects because their `{{pk_field}}` does not implement the `<=>` operator."
      {% end %}
    end

    include Comparable(self)

  end
end
