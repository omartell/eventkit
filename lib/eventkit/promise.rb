module Eventkit
  class Promise
    attr_reader :value
    alias_method :reason, :value

    def initialize
      @on_fullfiled = []
      @on_rejected  = []
      @state = :pending
    end

    def pending?
      @state == :pending
    end

    def resolved?
      @state == :resolved
    end

    def rejected?
      @state == :rejected
    end

    def then(on_fullfiled_handler = nil, on_rejected_handler = nil)
      promise = Promise.new

      self.on_fullfiled { |value|
        begin
          if on_fullfiled_handler
            promise.resolve(on_fullfiled_handler.to_proc.call(value))
          else
            promise.resolve(value)
          end
        rescue => error
          promise.reject(error)
        end
      }

      self.on_rejected { |value|
        begin
          if on_rejected_handler
            promise.resolve(on_rejected_handler.to_proc.call(value))
          else
            promise.reject(value)
          end
        rescue => error
          promise.reject(error)
        end
      }

      promise
    end

    def resolve(value)
      return unless pending?

      @value = value
      if value.respond_to?(:then)
        value.then(->(v) { deliver_resolved(v) }, ->(v) { deliver_rejected(v) })
      else
        deliver_resolved(value)
        @state = :resolved
      end
    end

    def reject(value)
      return unless pending?

      @value = value
      deliver_rejected(value)
      @state = :rejected
    end

    def on_fullfiled(&handler)
      fail TypeError, 'Given handler does not respond to #call' unless handler.respond_to?(:call)

      if resolved?
        handler.call(value)
      else
        @on_fullfiled << handler
      end
    end

    def on_rejected(&handler)
      fail TypeError, 'Given handler does not respond to #call' unless handler.respond_to?(:call)

      if rejected?
        handler.call(value)
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

