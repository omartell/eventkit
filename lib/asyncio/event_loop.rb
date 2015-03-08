module AsyncIO
  class EventLoop
    def initialize
      @reading = {}
    end

    def tick
      ready_read, _, _ = IO.select(@reading.keys)
      ready_read.each do |io|
        io.send(@reading[io])
      end
    end

    def register_read(io, read_listener)
      @reading[io] = read_listener
    end
  end
end
