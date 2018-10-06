module Granite::ValidationHelpers
  macro validate_greater_than(field, amount, or_equal_to = false)
    validate {{field}}, "#{{{field}}} must be greater than#{{{or_equal_to}} ? " or equal to" : ""} #{{{amount}}}", Proc(self, Bool).new { |model| (model.{{field.id}}.not_nil! {% if or_equal_to %} >= {% else %} > {% end %} {{amount.id}}) }
  end

  macro validate_less_than(field, amount, or_equal_to = false)
    validate {{field}}, "#{{{field}}} must be less than#{{{or_equal_to}} ? " or equal to" : ""} #{{{amount}}}", Proc(self, Bool).new { |model| (model.{{field.id}}.not_nil! {% if or_equal_to %} <= {% else %} < {% end %} {{amount.id}}) }
  end
end
