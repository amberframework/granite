module Granite::ValidationHelpers
  macro validate_min_length(field, length)
    validate {{field}}, "#{{{field}}} is too short. It must be at least #{{{length}}}", Proc(self, Bool).new { |model| (model.{{field.id}}.not_nil!.size >= {{length.id}}) }
  end

  macro validate_max_length(field, length)
    validate {{field}}, "#{{{field}}} is too long. It must be at most #{{{length}}}", Proc(self, Bool).new { |model| (model.{{field.id}}.not_nil!.size <= {{length.id}}) }
  end
end
