module Granite
  class RecordNotSaved < ::Exception
    getter model : Granite::Base

    def initialize(class_name : String, @model : Granite::Base)
      super("Could not process #{class_name}: #{model.errors.first.message}")
    end
  end

  class RecordNotDestroyed < ::Exception
    getter model : Granite::Base

    def initialize(class_name : String, @model : Granite::Base)
      super("Could not destroy #{class_name}: #{model.errors.first.message}")
    end
  end
end
