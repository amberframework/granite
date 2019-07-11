module Granite
  class Connections
    class_getter registered_connections = [] of Granite::Adapter::Base

    def self.<<(adapter : Granite::Adapter::Base) : Nil
      raise "Adapter with name '#{adapter.name}' has already been registered." if @@registered_connections.any? { |conn| conn.name == adapter.name }
      @@registered_connections << adapter
    end

    def self.get_connection(name : String) : Granite::Adapter::Base?
      registered_connections.find { |conn| conn.name == name }
    end
  end
end
