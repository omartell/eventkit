require 'set'
require 'eventkit/timer'

module Eventkit
  class EventLoopAlreadyStartedError < StandardError; end

  class EventLoop
    attr_reader :select_interval
    private :select_interval

    def initialize(config = {})
      @read_handlers = Hash.new { |h, k| h[k] = [] }
      @write_handlers = Hash.new { |h, k| h[k] = [] }
      @select_interval = config.fetch(:select_interval, 1 / 100_000)
      @timers = SortedSet.new
      @stopped = false
      @started = false
    end

    def start(&_block)
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
      ready_read, ready_write, _ = IO.select(@read_handlers.keys, @write_handlers.keys, [], select_interval)
      ready_read.each do |io|
        @read_handlers.fetch(io).each { |handler| handler.call(io) }
      end if ready_read

      ready_write.each do |io|
        @write_handlers.fetch(io).each { |handler| handler.call(io) }
      end if ready_write

      @timers.each { |timer| timer.handler.call if timer.expired? }
      @timers = @timers.reject(&:expired?)
      nil
    end

    def on_next_tick(&handler)
      register_timer(run_in: 0, &handler)
    end

    def register_timer(options, &handler)
      @timers << Timer.new(options.fetch(:run_in), handler)
    end

    def register_read(io, &listener)
      @read_handlers[io] += [listener]
    end

    def deregister_read(io, listener = nil)
      if listener
        @read_handlers[io] -= [listener]
      else
        @read_handlers[io] = []
      end
    end

    def register_write(io, &listener)
      @write_handlers[io] += [listener]
    end

    def deregister_write(io, listener = nil)
      if listener
        @write_handlers[io] -= [listener]
      else
        @write_handlers[io] = []
      end
    end
  end
end

