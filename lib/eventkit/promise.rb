module Eventkit
  class Promise
    attr_reader :value, :reason

    def initialize
      @on_fullfiled = []
      @on_rejected  = []
      @state = :pending
    end

    def then(on_fullfiled: nil, on_rejected: nil)
      self.on_fullfiled(&on_fullfiled) if on_fullfiled
      self.on_rejected(&on_rejected) if on_rejected
    end

    def resolve(value)
      return unless @state == :pending
      @value = value
      if value.respond_to?(:then)
        value.then(on_fullfiled: ->(v) { deliver_resolved(v) },
                   on_rejected:  ->(v) { deliver_rejected(v) })
      else
        deliver_resolved(value)
        @state = :resolved
      end
    end

    def reject(value)
      return unless @state == :pending
      @reason = value
      deliver_rejected(value)
      @state = :rejected
    end

    def on_fullfiled(&handler)
      fail ArgumentError, 'Given handler does not respond to #call' unless handler.respond_to?(:call)

      if @state == :resolved
        handler.call(value)
      else
        @on_fullfiled << handler
      end
    end

    def on_rejected(&handler)
      fail ArgumentError, 'Given handler does not respond to #call' unless handler.respond_to?(:call)

      if @state == :rejected
        handler.call(reason)
      else
        @on_rejected << handler
      end
    end

    private

    def deliver_resolved(value)
      @on_fullfiled.each { |handler| handler.call(value) }
    end

    def deliver_rejected(value)
      @on_rejected.each { |handler| handler.call(value) }
    end
  end
end
