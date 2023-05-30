module Granite
  class Connections
    class_property connection_switch_wait_period : Int64 = 2000
    class_getter registered_connections = [] of {writer: Granite::Adapter::Base, reader: Granite::Adapter::Base}

    # Registers the given *adapter*.  Raises if an adapter with the same name has already been registered.
    def self.<<(adapter : Granite::Adapter::Base) : Nil
      raise "Adapter with name '#{adapter.name}' has already been registered." if @@registered_connections.any? { |conn| conn[:writer].name == adapter.name }
      @@registered_connections << {writer: adapter, reader: adapter}
    end

    def self.<<(data : NamedTuple(name: String, reader: String, writer: String, adapter_type: Granite::Adapter::Base.class)) : Nil
      raise "Adapter with name '#{data[:name]}' has already been registered." if @@registered_connections.any? { |conn| conn[:writer].name == data[:name] }

      writer_adapter = data[:adapter_type].new(name: data[:name], url: data[:writer])

      # if reader/writer reference the same db. Make them point to the same granite adapter.
      # This avoids connection pool duplications on the same database.
      if (data[:reader] == data[:writer])
        return @@registered_connections << {writer: writer_adapter, reader: writer_adapter}
      end

      reader_adapter = data[:adapter_type].new(name: data[:name], url: data[:reader])
      @@registered_connections << {writer: writer_adapter, reader: reader_adapter}
    end

    # Returns a registered connection with the given *name*, otherwise `nil`.
    def self.[](name : String) : {writer: Granite::Adapter::Base, reader: Granite::Adapter::Base}?
      registered_connections.find { |conn| conn[:writer].name == name }
    end

    def self.first_writer
      @@registered_connections.first?.not_nil![:writer]
    end

    def self.first_reader
      @@registered_connections.first?.not_nil![:reader]
    end
  end
end
