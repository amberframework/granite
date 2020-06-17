module Granite::EagerLoading
  module InstanceMethods
    def set_eager_loading_container(@__eager_loading_container : Container = Granite::EagerLoading::Container.new())
    end
    def get_eager_loading_container()
      @__eager_loading_container || Granite::EagerLoading::Container.new()
    end
  end

  module ClassMethods
    def includes(value : Symbol)
      Granite::Querying(self).new(self.select_container, self.adapter, self.primary_name, self.quoted_table_name, self.name, [value] of Symbol)
    end
  end

  class ModelWrapper
    forward_missing_to model
    def initialize(@model : Granite::Base)
    end
  end

  class Container
    def initialize(@includes : Array(Symbol) = [] of Symbol, @ids : Array(Int64 | Int32) = [] of Int64 | Int32)
      @collection = [] of ModelWrapper
    end

    def load_collection(class_name, key)
      coond = Hash(Symbol, Array(Int32)).new
      return class_name.none if @ids.size == 0
      coond[:book_id] = [1,2]
      #coond[key] = @ids
      @collection = class_name.where(coond).select.map{|item| ModelWrapper.new(item)}
      @ids = [] of Int32 | Int64
      @collection
    end

    def add_id(id : Nil)
    end

    def add_id(id : Int64 | Int32)
      @ids << id
    end

    def resolve(class_name, key, through, id)
      items = load_collection(class_name, key)
      result = items.select{ |item| item.book_id == id}
      puts result.inspect
      result
    end
  end
end
