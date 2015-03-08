require 'spec_helper'
require 'support/async_helper'
require 'socket'
require 'asyncio'

module AsyncIO
  RSpec.describe EventLoop do
    let(:event_loop) do
      EventLoop.new
    end

    let(:tcp_server) do
      TCPServer.new('localhost', 9595)
    end

    let(:another_tcp_server) do
      TCPServer.new('localhost', 9494)
    end

    after do
      tcp_server.close
      another_tcp_server.close
    end

    it 'notifies when a single read operation is ready' do
      fake_server = double(to_io: tcp_server, connection_read_ready: nil)

      event_loop.register_read(fake_server, &fake_server.method(:connection_read_ready))

      TCPSocket.new('localhost', 9595)

      event_loop.tick

      expect(fake_server).to have_received(:connection_read_ready).once.with(fake_server)
    end

    it 'notifies when multiple read operations are ready' do
      fake_server = double(to_io: tcp_server, connection_read_ready: nil)
      another_fake_server = double(to_io: another_tcp_server, new_connection: nil)

      event_loop.register_read(fake_server, &fake_server.method(:connection_read_ready))
      event_loop.register_read(another_fake_server, &another_fake_server.method(:new_connection))

      TCPSocket.new('localhost', 9595)
      TCPSocket.new('localhost', 9494)

      event_loop.tick

      expect(fake_server).to have_received(:connection_read_ready).once.with(fake_server)
      expect(another_fake_server).to have_received(:new_connection).once.with(another_fake_server)
    end

    it 'allows a single object to register reads on multiple io objects' do
      manager = double(connection_read_ready: nil, another_connection: nil)

      event_loop.register_read(tcp_server, &manager.method(:connection_read_ready))
      event_loop.register_read(another_tcp_server, &manager.method(:another_connection))

      TCPSocket.new('localhost', 9595)
      TCPSocket.new('localhost', 9494)

      expect(manager).to receive(:connection_read_ready).once.with(tcp_server)
      expect(manager).to receive(:another_connection).once.with(another_tcp_server)

      event_loop.tick
    end

    it 'allows to register multiple read handlers on a single io object' do
      manager = double(connection_read_ready: nil)
      another_manager = double(new_connection: nil)

      event_loop.register_read(tcp_server, &manager.method(:connection_read_ready))
      event_loop.register_read(tcp_server, &another_manager.method(:new_connection))

      TCPSocket.new('localhost', 9595)

      expect(manager).to receive(:connection_read_ready).once.with(tcp_server)
      expect(another_manager).to receive(:new_connection).once.with(tcp_server)

      event_loop.tick
    end

    it 'allows to deregister read handlers' do
      manager = double(connection_read_ready: nil)

      event_loop.register_read(tcp_server, &manager.method(:connection_read_ready))
      event_loop.deregister_read(tcp_server, &manager.method(:connection_read_ready))

      TCPSocket.new('localhost', 9595)

      expect(manager).not_to receive(:new_connection)

      event_loop.tick
    end
  end
end
