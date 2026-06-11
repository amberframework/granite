require "atomic"

class Fiber
  property granite_adapters : Hash(String, Granite::Adapter::Base)?
end

module Granite::ConnectionManagement
  macro included
    # Default value for the time a model waits before using a reader
    # database connection for read operations
    # all models use this value. Change it
    # to change it in all Granite::Base models.
    class_property connection_switch_wait_period : Int32 = Granite::Connections.connection_switch_wait_period
    @@last_write_time = Atomic(Int64).new(Time.utc.to_unix_ms)

    # class_property current_adapter : Granite::Adapter::Base?
    class_property reader_adapter : Granite::Adapter::Base?
    class_property writer_adapter : Granite::Adapter::Base?

    def self.last_write_time
      Time.unix_ms(@@last_write_time.get)
    end

    # This is done this way because callbacks don't work on class mthods
    def self.update_last_write_time
      @@last_write_time.set(Time.utc.to_unix_ms)
    end

    def update_last_write_time
      self.class.update_last_write_time
    end

    def self.time_since_last_write
      Time.utc - last_write_time
    end

    def time_since_last_write
      self.class.time_since_last_write
    end

    def self.switch_to_reader_adapter
      if time_since_last_write > @@connection_switch_wait_period.milliseconds
        fiber_adapters = Fiber.current.granite_adapters ||= {} of String => Granite::Adapter::Base
        if reader = @@reader_adapter
          fiber_adapters[self.name] = reader
        end
      end
    end

    def switch_to_reader_adapter
      self.class.switch_to_reader_adapter
    end

    def self.switch_to_writer_adapter
      fiber_adapters = Fiber.current.granite_adapters ||= {} of String => Granite::Adapter::Base
      if writer = @@writer_adapter
        fiber_adapters[self.name] = writer
      end
    end

    def switch_to_writer_adapter
      self.class.switch_to_writer_adapter
    end

    def self.schedule_adapter_switch
      return if @@writer_adapter == @@reader_adapter

      # In M:N multithreading, spawning a fiber to mutate global state or Fiber local state
      # is no longer safe or deterministic. We rely on the dynamic check in `adapter` method
      # and the Fiber-local scope.
    end

    def schedule_adapter_switch
      self.class.schedule_adapter_switch
    end

    def self.adapter
      fiber_adapters = Fiber.current.granite_adapters
      
      if fiber_adapters && (adapter = fiber_adapters[self.name]?)
        return adapter
      end
      
      if time_since_last_write > @@connection_switch_wait_period.milliseconds
        if reader = @@reader_adapter
          return reader
        end
      else
        if writer = @@writer_adapter
          return writer
        end
      end
      
      begin
        Granite::Connections.registered_connections.first?.not_nil![:writer]
      rescue NilAssertionError
        raise "No registered connections found"
      end
    end
  end

  macro connection(name)
    {% name = name.id.stringify %}

    error_message = "Connection #{{{name}}} not found in Granite::Connections.
    Available connections are:

    #{Granite::Connections.registered_connections.map{ |conn| "#{conn[:writer].name}"}.join(", ")}"

    raise error_message if Granite::Connections[{{name}}].nil?

    self.writer_adapter = Granite::Connections[{{name}}].not_nil![:writer]
    self.reader_adapter = Granite::Connections[{{name}}].not_nil![:reader]
    # self.current_adapter = @@writer_adapter
  end
end
