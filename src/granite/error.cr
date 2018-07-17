class Granite::Error
  property field, message

  def initialize(@field : (String | Symbol | JSON::Any), @message : String? = "")
  end

  def to_s
    if @field == :base
      @message
    else
      "#{@field.to_s.capitalize} #{message}"
    end
  end
end
