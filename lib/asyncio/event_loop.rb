module AsyncIO
  class EventLoop
    def initialize
      @reading = Hash.new { |h, k| h[k] = [] }
      @writing = Hash.new { |h, k| h[k] = [] }
      @stopped = false
    end

    def start
      loop do
        break if stopped?
        tick
      end
    end

    def stop
      @stopped = true
    end

    def stopped?
      @stopped
    end

    def tick
      ready_read, ready_write, _ = IO.select(@reading.keys, @writing.keys, [], 1)
      ready_read.each do |io|
        @reading[io].each{ |handler| handler.call(io) }
      end if ready_read

      ready_write.each do |io|
         @writing[io].each{ |handler| handler.call(io) }
      end if ready_write
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

    def deregister_write(io, write_listener)
      if write_listener
        @writing[io] -= [write_listener]
      else
        @writing[io] = []
      end
    end
  end
end
