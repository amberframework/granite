module Granite::ValidationHelpers
  macro validate_exclusion(field, excluded_values)
    validate {{field}}, "#{{{field.capitalize}}} got reserved values. Reserved values are #{{{excluded_values.join(',')}}}", Proc(self, Bool).new { |model| !{{excluded_values}}.includes? model.{{field.id}}}
  end
end
