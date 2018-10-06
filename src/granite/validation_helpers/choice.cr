module Granite::ValidationHelpers
  macro validate_is_valid_choice(field, choices)
    validate {{field}}, "#{{{field}}} has an invalid choice. Valid choices are: #{{{choices.join(',')}}}", Proc(self, Bool).new { |model| {{choices}}.includes? model.{{field.id}} }
  end
end
