module AsyncIO
  class EventLoopAlreadyStartedError < StandardError;end
  class EventLoop
    attr_reader :interval
    private :interval

    def initialize(config = {})
      @read_handlers = Hash.new { |h, k| h[k] = [] }
      @write_handlers = Hash.new { |h, k| h[k] = [] }
      @stopped = false
      @started = false
      @interval = config.fetch(:interval_in_seconds, 1/100_000)
    end

    def start(&block)
      if @started
        fail EventLoopAlreadyStartedError, 'This event loop instance has already started running'
      else
        @started = true
      end

      loop do
        break if stopped?
        tick
      end
    end

    def stop
      @stopped = true
      @started = false
    end

    def stopped?
      @stopped
    end

    def tick
      ready_read, ready_write, _ = IO.select(@read_handlers.keys, @write_handlers.keys, [], interval)
      ready_read.each do |io|
        @read_handlers[io].each{ |handler| handler.call(io) }
      end if ready_read

      ready_write.each do |io|
         @write_handlers[io].each{ |handler| handler.call(io) }
      end if ready_write
    end

    def register_read(io, &read_listener)
      @read_handlers[io] += [read_listener]
    end

    def deregister_read(io, read_listener = nil)
      if read_listener
        @read_handlers[io] -= [read_listener]
      else
        @read_handlers[io] = []
      end
    end

    def register_write(io, &write_listener)
      @write_handlers[io] += [write_listener]
    end

    def deregister_write(io, write_listener = nil)
      if write_listener
        @write_handlers[io] -= [write_listener]
      else
        @write_handlers[io] = []
      end
    end
  end
end
