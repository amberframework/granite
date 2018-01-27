class Granite::ORM::Error
  property field, message

  def initialize(@field : (String | Symbol), @message : String? = "")
  end

  def to_s
    if @field == :base
      @message
    else
      "#{@field.to_s.capitalize} #{message}"
    end
  end
end
