module AsyncIO
  class EventLoop
    def initialize
      @reading = Hash.new do |h, k|
        h[k] = []
      end

      @writing = Hash.new do |h, k|
        h[k] = []
      end
    end

    def tick
      ready_read, ready_write, _ = IO.select(@reading.keys, @writing.keys, [], 1)
      (ready_read || []).each do |io|
         @reading[io].each{ |handler| handler.call(io) }
      end

      (ready_write || []).each do |io|
         @writing[io].each{ |handler| handler.call(io) }
      end
    end

    def register_read(io, &read_listener)
      @reading[io] += [read_listener]
    end

    def deregister_read(io, &read_listener)
      @reading[io] -= [read_listener]
    end

    def register_write(io, &write_listener)
      @writing[io] += [write_listener]
    end

    def deregister_write(io, &write_listener)
      @writing[io] -= [write_listener]
    end
  end
end
