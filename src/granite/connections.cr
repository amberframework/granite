module Granite
  class Connections
    class_property connection_switch_wait_period : Int64 = 2000
    class_getter registered_connections = [] of {writer: Granite::Adapter::Base, reader: Granite::Adapter::Base}

    # Registers the given *adapter*.  Raises if an adapter with the same name has already been registered.
    def self.<<(adapter : Granite::Adapter::Base) : Nil
      raise "Adapter with name '#{adapter.name}' has already been registered." if @@registered_connections.any? { |conn| conn[:writer].name == adapter.name }
      @@registered_connections << {writer: adapter, reader: adapter}
    end

    # TODO: Find cleaner type restriction method
    def self.<<(*, name : String, reader : String, writer : String, adapter_type : Granite::Adapter::Base.class) : Nil
      reader_adapter = adapter_type.new(name: name, url: reader)
      writer_adapter = adapter_type.new(name: name, url: writer)
      @@registered_connections << {writer: writer_adapter, reader: reader_adapter}
    end

    # Returns a registered connection with the given *name*, otherwise `nil`.
    def self.[](name : String) : {writer: Granite::Adapter::Base, reader: Granite::Adapter::Base}?
      registered_connections.find { |conn| conn[:writer].name == name }
    end
  end
end
