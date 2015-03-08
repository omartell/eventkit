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

      event_loop.register_read(fake_server, :connection_read_ready)

      TCPSocket.new('localhost', 9595)

      event_loop.tick

      expect(fake_server).to have_received(:connection_read_ready).at_least(:once)
    end

    it 'notifies when multiple read operations are ready' do
      tcp_server = TCPServer.new('localhost', 9595)
      another_tcp_server = TCPServer.new('localhost', 9494)

      fake_server = double(to_io: tcp_server, connection_read_ready: nil)
      another_fake_server = double(to_io: another_tcp_server, new_connection: nil)

      event_loop.register_read(fake_server, :connection_read_ready)
      event_loop.register_read(another_fake_server, :new_connection)

      TCPSocket.new('localhost', 9595)
      TCPSocket.new('localhost', 9494)

      event_loop.tick

      expect(fake_server).to have_received(:connection_read_ready).at_least(:once)
      expect(another_fake_server).to have_received(:new_connection).at_least(:once)
    end
  end
end
