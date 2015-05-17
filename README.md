# Eventkit

A basic toolkit for asynchronous event driven applications. The
current version includes an Event Loop to perform non blocking IO and
a promises A+ implementation to coordinate asychronous tasks.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'eventkit'
```

## Event Loop Usage

Eventkit provides a basic Event Loop on top of Ruby's IO.select to perform non blocking IO.
Callbacks can be registered to monitor the readability or writability of IO objects.
These callbacks are executed when the IO object is ready to be read or written to.

Another feature is timers, which allows you to execute code at some point in the future.

```ruby
require 'eventkit'

# Getting notified when an IO object is ready to be read or written
event_loop = Eventkit::EventLoop.new

server = TCPServer.new('localhost', 9595)

client = TCPSocket.new('localhost', 9595)

event_loop.register_read(server) do |server|
  # This will be executed every time a new connection is ready to be accepted
  connection, _ = server.accept_nonblock
  event_loop.register_write(connection) do |connection|
    bytes_written = connection.write_nonblock('hello world')
  end
end

event_loop.start


# Unsubscribing from notifications
# A single read
event_loop.deregister_read(io_object, handler)

# A single write
event_loop.deregister_write(io_object, handler)

# All handlers
event_loop.deregister_write(io_object)
event_loop.deregister_read(io_object)


# Registering a handler to be run on the next tick
event_loop = Eventkit::EventLoop.new

event_loop.on_next_tick do
  puts 'hello world'
  event_loop.stop
end

event_loop.start


# Registering timers

event_loop = Eventkit::EventLoop.new

event_loop.register_timer(run_in: 5) do
  # Block executes after 5 seconds have passed
  puts 'hello world'
  event_loop.stop
end

event_loop.start
```

## Promises Usage

Eventkit also provides an implementation of the [Promise A+ specification](https://promisesaplus.com/),
which allows you coordinate different asynchronous tasks while still programming with values.

If you're only interested in promises, then eventkit-promise is also available as a [separate gem] (https://rubygems.org/gems/eventkit-promise).

```ruby
require 'eventkit/promise'

# Resolving a promise

promise = Eventkit::Promise.new

promise.then(->(value) { value + 1 })

promise.resolve(1)

promise.value # => 1

# Rejecting a promise

promise = Eventkit::Promise.new

promise.then(
  ->(value) {
    value + 1
  },
  ->(error) {
    log(error.message)
  }
)

promise.reject(NoMethodError.new('Undefined method #call'))

promise.reason # => <NoMethodError: undefined method #call>

# Chaining promises

promise_a = Eventkit::Promise.new

promise_b = promise_a
  .then(->(v) { v + 1 })
  .then(->(v) { v + 1 })
  .then(->(v) { v + 1 })

promise_b.catch { |error|
# Handle errors raised by any of the previous handlers
}

promise_a.resolve(1)

promise_a.value # => 1
promise_b.value # => 4

# Resolving and fullfiling with another promise

promise_a = Eventkit::Promise.new
promise_b = Eventkit::Promise.new

promise_a.resolve(promise_b)

promise_b.resolve('foobar')

promise_a.value # => foobar

# Resolving and rejecting with another promise

promise_a = Eventkit::Promise.new
promise_b = Eventkit::Promise.new

promise_a.resolve(promise_b)

promise_b.reject('Ooops can not continue')

promise_a.reason # => 'Ooops can not continue'

# Initializing with a block

promise = Promise.new do |p|
  p.resolve('foobar')
end

promise.value # => 'foobar'

```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/eventkit/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
6. Happy Hacking!
