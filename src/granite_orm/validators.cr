require "./error"

module Granite::ORM::Validators
  getter errors = [] of Error

  macro included
    macro inherited
      @@validators = Array({field: Symbol, message: String, block: Proc(self, Bool)}).new
      @validators = Array({field: Symbol, message: String, block: Proc(Bool)}).new
      def validate!
      end
    end
  end

  # First option: syntax support using procs
  macro validate(message, block)
    @@validators << {field: :base, message: {{message}}, block: {{block}}}
  end

  macro validate(field, message, block)
    @@validators << {field: {{field}}, message: {{message}}, block: {{block}}}
  end

  # Second option: syntax sypport using blocks
  macro validate(message)
    def validate!
      previous_def
      @validators << {field: :base, message: {{message}}, block: ->{{{yield}}}}
    end
  end

  macro validate(field, message)
    def validate!
      previous_def
      @validators << {field: {{field}}, message: {{message}}, block: ->{{{yield}}}}
    end
  end

  # Analyze validation blocks and procs
  # Note: This method checks two type of validation macros
  #
  # By example:
  # ```
  # validate :name, "name can't be blank" do
  #   !name.to_s.blank?
  # end
  #
  # validate :name, "name can't be blank", -> (user : User) do
  #   !user.name.to_s.blank?
  # end
  # ```
  def valid?
    @@validators.each do |validator|
      unless validator[:block].call(self)
        error << Error.new(validator[:field], validator[:message])
      end
    end
    validate!
    @validators.each do |validator|
      unless validator[:block].call
        errors << Error.new(validator[:field], validator[:message])
      end
    end
    errors.empty?
  end
end
