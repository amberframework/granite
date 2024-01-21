module Granite::ConnectionManagement
  macro included
    # Default value for the time a model waits before using a reader
    # database connection for read operations
    # all models use this value. Change it
    # to change it in all Granite::Base models.
    class_property connection_switch_wait_period : Int32 = Granite::Connections.connection_switch_wait_period
    @@last_write_time = Time.monotonic

    class_property current_adapter : Granite::Adapter::Base?
    class_property reader_adapter : Granite::Adapter::Base?
    class_property writer_adapter : Granite::Adapter::Base?

    def self.last_write_time
      @@last_write_time
    end

    # This is done this way because callbacks don't work on class mthods
    def self.update_last_write_time
      @@last_write_time = Time.monotonic
    end

    def update_last_write_time
      self.class.update_last_write_time
    end

    def self.time_since_last_write
      Time.monotonic - @@last_write_time
    end

    def time_since_last_write
      self.class.time_since_last_write
    end

    def self.switch_to_reader_adapter
      if time_since_last_write > @@connection_switch_wait_period.milliseconds
        @@current_adapter = @@reader_adapter
      end
    end

    def switch_to_reader_adapter
      self.class.switch_to_reader_adapter
    end

    def self.switch_to_writer_adapter
      @@current_adapter = @@writer_adapter
    end

    def switch_to_writer_adapter
      self.class.switch_to_writer_adapter
    end

    def self.schedule_adapter_switch
      return if @@writer_adapter == @@reader_adapter

      spawn do
        sleep @@connection_switch_wait_period.milliseconds
        switch_to_reader_adapter
      end

      Fiber.yield
    end

    def schedule_adapter_switch
      self.class.schedule_adapter_switch
    end

    def self.adapter
      begin
        @@current_adapter.not_nil!
      rescue NilAssertionError
        Granite::Connections.registered_connections.first?.not_nil![:writer]
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
    self.current_adapter = @@writer_adapter
  end
end
