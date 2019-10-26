module Granite::ValidationHelpers
  macro validate_uniqueness(field)
    validate {{field}}, "#{{{field}}} should be unique", -> (model: self) do
      return true if model.{{field.id}}.nil?

      instance = self.find_by({{field.id}}: model.{{field.id}})

      !(instance && instance.id? != model.id?)
    end
  end
end
