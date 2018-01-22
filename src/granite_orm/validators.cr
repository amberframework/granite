require "./error"

module Granite::ORM::Validators
  property errors = [] of Error

  macro included
    macro inherited
      @@validators = Array({field: Symbol, message: String, block: Proc(Bool)}).new
    end
  end

  def validate!
  end

  macro validate(message)
    def validate!
      previous_def
      @@validators << {field: :base, message: {{message}}, block: ->{{{yield}}}}
    end
  end

  macro validate(field, message)
    def validate!
      previous_def
      @@validators << {field: {{field}}, message: {{message}}, block: ->{{{yield}}}}
    end
  end

  def valid?
    validate!
    @@validators.each do |validator|
      unless validator[:block].call
        errors << Error.new(validator[:field], validator[:message])
      end
    end
    errors.empty?
  end
end
