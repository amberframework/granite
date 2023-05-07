module Granite
  class Connections
    class_getter registered_connections = [] of {writer: Granite::Adapter::Base, reader: Granite::Adapter::Base}

    # Registers the given *adapter*.  Raises if an adapter with the same name has already been registered.
    def self.<<(adapter : Granite::Adapter::Base) : Nil
      raise "Adapter with name '#{adapter.name}' has already been registered." if @@registered_connections.any? { |conn| conn[:writer].name == adapter.name }
      @@registered_connections << {writer: adapter, reader: adapter}
    end

    # Returns a registered connection with the given *name*, otherwise `nil`.
    def self.[](name : String) : {writer: Granite::Adapter::Base, reader: Granite::Adapter::Base}?
      registered_connections.find { |conn| conn[:writer].name == name }
    end
  end
end
