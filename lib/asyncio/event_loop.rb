module AsyncIO
  class EventLoop
    def initialize
      @reading = []
    end

    def tick
      ready_read, _, _ = IO.select(@reading)
      ready_read.each do |io|
        io.connection_read_ready
      end
    end

    def register_read(io, read_listener)
      @reading << io
    end
  end
end
