require 'spec_helper'
require 'support/async_helper'
require 'socket'
require 'asyncio'

module AsyncIO
  RSpec.describe EventLoop do
    include AsyncHelper

    let!(:event_loop) { EventLoop.new(interval_in_seconds: 1/100_000) }

    let!(:tcp_server) { TCPServer.new('localhost', 9595) }

    let!(:another_tcp_server) { TCPServer.new('localhost', 9494) }

    let!(:tcp_socket) { TCPSocket.new('localhost', 9595) }

    let!(:another_tcp_socket) { TCPSocket.new('localhost', 9494) }

    after do
      tcp_server.close
      another_tcp_server.close
      tcp_socket.close
      another_tcp_socket.close
    end

    it 'allows to start and stop the event loop' do
      listener = double(handle_event: nil)

      handler = listener.method(:handle_event).to_proc

      event_loop.register_write(tcp_socket, &handler)

      Thread.new { event_loop.stop }

      event_loop.start

      eventually do
        expect(listener).to have_received(:handle_event).once
      end
    end

    it 'does not allow to start the event loop once it has started' do
      expect do
        listener = double(:listener)

        allow(listener).to receive(:handle_event) do |_io|
          event_loop.start
        end

        event_loop.register_write(tcp_socket, &listener.method(:handle_event))

        event_loop.start
      end.to raise_error(EventLoopAlreadyStartedError)
    end

    it 'allows to restart the event loop' do
      expect do
        listener = double(:listener)

        allow(listener).to receive(:handle_event) do |_io|
          event_loop.stop
          event_loop.start
        end

        event_loop.register_write(tcp_socket, &listener.method(:handle_event))

        event_loop.start
      end.not_to raise_error
    end

    it 'notifies when a single read operation is ready' do
      fake_server = double(to_io: tcp_server, connection_read_ready: nil)

      event_loop.register_read(fake_server, &fake_server.method(:connection_read_ready))

      event_loop.tick

      expect(fake_server).to have_received(:connection_read_ready).once.with(fake_server)
    end

    it 'notifies when a single write operation is ready' do
      fake_socket = double(to_io: tcp_socket, connection_write_ready: nil)

      event_loop.register_write(fake_socket, &fake_socket.method(:connection_write_ready))

      event_loop.tick

      expect(fake_socket).to have_received(:connection_write_ready).once.with(fake_socket)
    end

    it 'notifies when multiple write operations are ready' do
      fake_socket = double(to_io: tcp_socket, connection_write_ready: nil)
      another_fake_socket = double(to_io: another_tcp_socket, ready_to_write: nil)

      event_loop.register_write(fake_socket, &fake_socket.method(:connection_write_ready))
      event_loop.register_write(another_fake_socket, &another_fake_socket.method(:ready_to_write))

      event_loop.tick

      expect(fake_socket).to have_received(:connection_write_ready).once.with(fake_socket)
      expect(another_fake_socket).to have_received(:ready_to_write).once.with(another_fake_socket)
    end

    it 'notifies when multiple read operations are ready' do
      fake_server = double(to_io: tcp_server, connection_read_ready: nil)
      another_fake_server = double(to_io: another_tcp_server, new_connection: nil)

      event_loop.register_read(fake_server, &fake_server.method(:connection_read_ready))
      event_loop.register_read(another_fake_server, &another_fake_server.method(:new_connection))

      event_loop.tick

      expect(fake_server).to have_received(:connection_read_ready).once.with(fake_server)
      expect(another_fake_server).to have_received(:new_connection).once.with(another_fake_server)
    end

    it 'allows an object to register reads on multiple io objects' do
      listener = double(connection_read_ready: nil, another_connection: nil)

      event_loop.register_read(tcp_server, &listener.method(:connection_read_ready))
      event_loop.register_read(another_tcp_server, &listener.method(:another_connection))

      expect(listener).to receive(:connection_read_ready).once.with(tcp_server)
      expect(listener).to receive(:another_connection).once.with(another_tcp_server)

      event_loop.tick
    end

    it 'allows an object to register writes on multiple io objects' do
      listener = double(one_ready_to_write: nil, another_ready_to_write: nil)

      event_loop.register_write(tcp_socket, &listener.method(:one_ready_to_write))
      event_loop.register_write(another_tcp_socket, &listener.method(:another_ready_to_write))

      expect(listener).to receive(:one_ready_to_write).once.with(tcp_socket)
      expect(listener).to receive(:another_ready_to_write).once.with(another_tcp_socket)

      event_loop.tick
    end

    it 'allows to register multiple read handlers on a single io object' do
      listener = double(connection_read_ready: nil)
      another_listener = double(new_connection: nil)

      event_loop.register_read(tcp_server, &listener.method(:connection_read_ready))
      event_loop.register_read(tcp_server, &another_listener.method(:new_connection))

      expect(listener).to receive(:connection_read_ready).once.with(tcp_server)
      expect(another_listener).to receive(:new_connection).once.with(tcp_server)

      event_loop.tick
    end

    it 'allows to register multiple write handlers on a single io object' do
      listener = double(connection_write_ready: nil)
      another_listener = double(ready_to_write: nil)

      event_loop.register_write(tcp_socket, &listener.method(:connection_write_ready))
      event_loop.register_write(tcp_socket, &another_listener.method(:ready_to_write))

      expect(listener).to receive(:connection_write_ready).once.with(tcp_socket)
      expect(another_listener).to receive(:ready_to_write).once.with(tcp_socket)

      event_loop.tick
    end

    it 'allows to deregister read handlers' do
      listener = double(connection_read_ready: nil)
      handler = listener.method(:connection_read_ready).to_proc

      event_loop.register_read(tcp_server, &handler)
      event_loop.deregister_read(tcp_server, &handler)

      expect(listener).not_to receive(:connection_read_ready)

      event_loop.tick
    end

    it 'allows to deregister write handlers' do
      listener = double(connection_write_ready: nil)

      handler = listener.method(:connection_write_ready).to_proc

      event_loop.register_write(tcp_socket, &handler)
      event_loop.deregister_write(tcp_socket, handler)

      expect(listener).not_to receive(:connection_write_ready)

      event_loop.tick
    end

    it 'deregisters all write handlers for an io object' do
      listener = double(connection_write_ready: nil, another_write_event: nil)

      first_handler = listener.method(:connection_write_ready).to_proc
      second_handler = listener.method(:another_write_event).to_proc

      event_loop.register_write(tcp_socket, &first_handler)
      event_loop.register_write(tcp_socket, &second_handler)

      event_loop.deregister_write(tcp_socket)

      expect(listener).not_to receive(:connection_write_ready)
      expect(listener).not_to receive(:another_event)

      event_loop.tick
    end

    it 'deregisters all read handlers for an io object' do
      listener = double(connection_read_ready: nil, another_read_event: nil)

      first_handler = listener.method(:connection_read_ready).to_proc
      second_handler = listener.method(:another_read_event).to_proc

      connection = tcp_server.accept
      connection.write('hello world')

      event_loop.register_read(tcp_socket, &first_handler)
      event_loop.register_read(tcp_socket, &second_handler)

      event_loop.deregister_read(tcp_socket)

      expect(listener).not_to receive(:connection_read_ready)
      expect(listener).not_to receive(:another_event)

      event_loop.tick
    end

    it 'allows to register timers which will executed in order' do
      listener = double(timer_expired_a: nil,
                        timer_expired_b: nil,
                        timer_expired_c: nil,
                        timer_expired_d: nil)

      event_loop.register_timer(run_in: 2, &listener.method(:timer_expired_a))

      event_loop.register_timer(run_in: 3, &listener.method(:timer_expired_b))

      event_loop.register_timer(run_in: 1, &listener.method(:timer_expired_c))

      event_loop.register_timer(run_in: 5, &listener.method(:timer_expired_d))

      sleep(3.1)

      event_loop.tick

      expect(listener).to have_received(:timer_expired_c).ordered.once
      expect(listener).to have_received(:timer_expired_a).ordered.once
      expect(listener).to have_received(:timer_expired_b).ordered.once
      expect(listener).to_not have_received(:timer_expired_d)
    end

    it 'deregister timers as soon as they have expired' do
      listener = double(timer_expired: nil)

      event_loop.register_timer(run_in: 1, &listener.method(:timer_expired))

      sleep(2)

      event_loop.tick
      event_loop.tick

      expect(listener).to have_received(:timer_expired).once
    end
  end
end
