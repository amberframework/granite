module Granite
  class RecordInvalid < ::Exception
    def initialize(class_name : String | Nil)
      super("Could not process #{class_name}")
    end
  end

  class RecordNotDestroyed < ::Exception
    def initialize(class_name : String | Nil)
      super("Could not destroy #{class_name}")
    end
  end
end
