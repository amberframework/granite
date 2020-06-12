module Granite::EagerLoading
  module InstanceMethods
    def set_eager_loading_container(@__eager_loading_container : Container = Granite::EagerLoading::Container.new())
    end
    def get_eager_loading_container
      @__eager_loading_container || Granite::EagerLoading::Container.new()
    end
  end

  module ClassMethods
    def includes(value : Symbol)
      Granite::Querying(self).new(self.select_container, self.adapter, self.primary_name, self.quoted_table_name, self.name, [value] of Symbol)
    end
  end

  class Container
    def initialize(@includes : Array(Symbol) = [] of Symbol, @ids : Array(Int64 | Int32) = [] of Int64 | Int32)
    end

    def load_collection(class_name, key)
      coond = Hash(Symbol | String, Array(Int64|Int32)).new
      return if @ids.size == 0
      coond[key] = @ids
      puts coond.inspect
      #result = class_name.where(coond)
      @ids = [] of Int32 | Int64
      nil
    end

    def add_id(id : Nil)
    end

    def add_id(id : Int64)
      @ids << id
    end

    def add_id(id : Int32 | Nil)
      @ids << id if id
    end

    def resolve(class_name, key, through)
      -> { load_collection(class_name, key) }
    end
  end
end
