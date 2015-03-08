module AsyncIO
  class EventLoop
    def initialize
      @reading = {}
    end

    def tick
      ready_read, _, _ = IO.select(@reading.keys, [], [], 1)
      (ready_read || []).each do |io|
        @reading[io].call(io)
      end
    end

    def register_read(io, &read_listener)
      @reading[io] = read_listener
    end
  end
end
