require 'spec_helper'
require 'support/async_helper'
require 'socket'
require 'asyncio'

module AsyncIO
  RSpec.describe EventLoop do
    let!(:event_loop) { EventLoop.new }

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

    it 'allows a single object to register reads on multiple io objects' do
      manager = double(connection_read_ready: nil, another_connection: nil)

      event_loop.register_read(tcp_server, &manager.method(:connection_read_ready))
      event_loop.register_read(another_tcp_server, &manager.method(:another_connection))

      expect(manager).to receive(:connection_read_ready).once.with(tcp_server)
      expect(manager).to receive(:another_connection).once.with(another_tcp_server)

      event_loop.tick
    end

    it 'allows a single object to register writes on multiple io objects' do
      manager = double(one_ready_to_write: nil, another_ready_to_write: nil)

      event_loop.register_write(tcp_socket, &manager.method(:one_ready_to_write))
      event_loop.register_write(another_tcp_socket, &manager.method(:another_ready_to_write))

      expect(manager).to receive(:one_ready_to_write).once.with(tcp_socket)
      expect(manager).to receive(:another_ready_to_write).once.with(another_tcp_socket)

      event_loop.tick
    end

    it 'allows to register multiple read handlers on a single io object' do
      manager = double(connection_read_ready: nil)
      another_manager = double(new_connection: nil)

      event_loop.register_read(tcp_server, &manager.method(:connection_read_ready))
      event_loop.register_read(tcp_server, &another_manager.method(:new_connection))

      expect(manager).to receive(:connection_read_ready).once.with(tcp_server)
      expect(another_manager).to receive(:new_connection).once.with(tcp_server)

      event_loop.tick
    end

    it 'allows to register multiple write handlers on a single io object' do
      manager = double(connection_write_ready: nil)
      another_manager = double(ready_to_write: nil)

      event_loop.register_write(tcp_socket, &manager.method(:connection_write_ready))
      event_loop.register_write(tcp_socket, &another_manager.method(:ready_to_write))

      expect(manager).to receive(:connection_write_ready).once.with(tcp_socket)
      expect(another_manager).to receive(:ready_to_write).once.with(tcp_socket)

      event_loop.tick
    end

    it 'allows to deregister read handlers' do
      manager = double(connection_read_ready: nil)
      handler = manager.method(:connection_read_ready).to_proc

      event_loop.register_read(tcp_server, &handler)
      event_loop.deregister_read(tcp_server, &handler)

      expect(manager).not_to receive(:connection_read_ready)

      event_loop.tick
    end

    it 'allows to deregister write handlers' do
      manager = double(connection_write_ready: nil)

      handler = manager.method(:connection_write_ready).to_proc

      event_loop.register_write(tcp_socket, &handler)
      event_loop.deregister_write(tcp_socket, &handler)

      expect(manager).not_to receive(:connection_write_ready)

      event_loop.tick
    end
  end
end
