module Granite
  class Adapters
    class_getter registered_adapters = [] of Granite::Adapter::Base

    def self.<<(adapter : Granite::Adapter::Base)
      raise "Adapter with name '#{adapter.name}' has already been registered." if @@registered_adapters.any? { |registered_adapter| registered_adapter.name == adapter.name }
      @@registered_adapters << adapter
    end
  end
end
