class Granite::Error
  property field, message

  def initialize(@field : (String | Symbol | JSON::Any), @message : String? = "")
  end

  def to_s(io)
    if field == :base
      io << message
    else
      io << field.to_s.capitalize << " " << message
    end
  end
end

class Granite::ConversionError < Granite::Error
end
