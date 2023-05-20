module Granite::ConnectionManagement
  macro included
    class_property connection_switch_wait_period : Int64 = 2000
    @@last_write_time = Time.monotonic
    @@current_adapter : Granite::Adapter::Base?

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
      if time_since_last_write > 2.seconds
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
      spawn do
        sleep connection_switch_wait_period.milliseconds
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
end
