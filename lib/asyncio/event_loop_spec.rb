require 'spec_helper'
require 'support/async_helper'
require 'socket'
require 'asyncio'

module AsyncIO
  RSpec.describe EventLoop do
    let(:event_loop) do
      EventLoop.new
    end

    it 'notifies when a single read operation is ready' do
      tcp_server = TCPServer.new('localhost', 9595)
      fake_server = double(to_io: tcp_server, connection_read_ready: nil)

      event_loop.register_read(fake_server, &fake_server.method(:connection_read_ready))

      TCPSocket.new('localhost', 9595)

      event_loop.tick

      expect(fake_server).to have_received(:connection_read_ready).at_least(:once)

      tcp_server.close
    end

    it 'notifies when multiple read operations are ready' do
      tcp_server = TCPServer.new('localhost', 9595)
      another_tcp_server = TCPServer.new('localhost', 9494)

      fake_server = double(to_io: tcp_server, connection_read_ready: nil)
      another_fake_server = double(to_io: another_tcp_server, new_connection: nil)

      event_loop.register_read(fake_server, &fake_server.method(:connection_read_ready))
      event_loop.register_read(another_fake_server, &another_fake_server.method(:new_connection))

      TCPSocket.new('localhost', 9595)
      TCPSocket.new('localhost', 9494)

      event_loop.tick

      expect(fake_server).to have_received(:connection_read_ready).at_least(:once)
      expect(another_fake_server).to have_received(:new_connection).at_least(:once)

      tcp_server.close
      another_tcp_server.close
    end

    it 'allows an object to listen on multiple io objects' do
      tcp_server = TCPServer.new('localhost', 9595)
      another_tcp_server = TCPServer.new('localhost', 9494)

      manager = double(connection_read_ready: nil,
                       another_connection: nil)

      event_loop.register_read(tcp_server, &manager.method(:connection_read_ready))
      event_loop.register_read(another_tcp_server, &manager.method(:another_connection))

      TCPSocket.new('localhost', 9595)
      TCPSocket.new('localhost', 9494)

      expect(manager).to receive(:connection_read_ready).once.with(tcp_server)
      expect(manager).to receive(:another_connection).once.with(another_tcp_server)

      event_loop.tick

      tcp_server.close
      another_tcp_server.close
    end
  end
end
