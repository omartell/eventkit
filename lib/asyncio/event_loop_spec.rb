require 'spec_helper'
require 'support/async_helper'
require 'socket'
require 'asyncio'

module AsyncIO
  RSpec.describe EventLoop do
    let(:event_loop) do
      EventLoop.new
    end

    let(:server) do
      TCPServer.new('localhost', 9595)
    end

    it 'notifies when a single read operation is ready' do
      fake_server = double(to_io: server, connection_read_ready: nil)

      event_loop.register_read(fake_server, :connection_read_ready)

      TCPSocket.new('localhost', 9595)

      event_loop.tick

      expect(fake_server).to have_received(:connection_read_ready).at_least(:once)
    end
  end
end
