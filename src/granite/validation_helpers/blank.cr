module Granite::ValidationHelpers
  macro validate_not_blank(field)
    validate {{field}}, "#{{{field}}} must not be blank", Proc(self, Bool).new { |model| !model.{{field.id}}.to_s.blank? }
  end

  macro validate_is_blank(field)
    validate {{field}}, "#{{{field}}} must be blank", Proc(self, Bool).new { |model| model.{{field.id}}.to_s.blank? }
  end
end
