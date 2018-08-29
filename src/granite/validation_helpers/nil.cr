module Granite::ValidationHelpers
  macro validate_not_nil(field)
    validate {{field}}, "#{{{field}}} must not be nil", Proc(self, Bool).new { |model| !model.{{field.id}}.nil? }
  end

  macro validate_is_nil(field)
    validate {{field}}, "#{{{field}}} must be nil", Proc(self, Bool).new { |model| model.{{field.id}}.nil? }
  end
end
