class Granite::Error
  property field, message

  def initialize(@field : (String | Symbol | JSON::Any), @message : String? = "")
  end

  def to_s
    (@field == :base) ? @message : "#{@field.to_s.capitalize} #{message}"
  end
end
