require 'eventkit'

module Eventkit
  RSpec.describe Promise do
    describe 'is in a pending, fullfiled or rejected state' do
      it 'executes on fullfiled handlers when resolved' do
        promise = Promise.new
        expect do |block|
          promise.on_fullfiled(&block)
          promise.on_fullfiled(&block)
          promise.on_fullfiled(&block)
          promise.resolve(:foo)
        end.to yield_successive_args(:foo, :foo, :foo)
      end

      it 'executes on fullfiled handlers after resolved' do
        promise = Promise.new
        expect do |block|
          promise.resolve(:foo)
          promise.on_fullfiled(&block)
        end.to yield_successive_args(:foo)
      end

      it 'only executes on fullfiled handlers once even if resolved multiple times' do
        promise = Promise.new
        expect do |block|
          promise.on_fullfiled(&block)
          promise.resolve(:foo)
          promise.resolve(:foo)
        end.to yield_control.once
      end

      it 'executes on fullfiled handlers in the same order as the originating calls' do
        promise = Promise.new
        expect do |block|
          promise.on_fullfiled { block.to_proc.call(1) }
          promise.on_fullfiled { block.to_proc.call(2) }
          promise.on_fullfiled { block.to_proc.call(3) }
          promise.resolve(:foo)
        end.to yield_successive_args(1, 2, 3)
      end

      it 'executes on rejected handlers when rejected' do
        promise = Promise.new
        expect do |block|
          promise.on_rejected(&block)
          promise.on_rejected(&block)
          promise.on_rejected(&block)
          promise.reject(:error)
        end.to yield_successive_args(:error, :error, :error)
      end

      it 'only executes on rejected handlers once event if rejected multiple times' do
        promise = Promise.new
        expect do |block|
          promise.on_rejected(&block)
          promise.reject(:error)
          promise.reject(:error)
        end.to yield_control.once
      end

      it 'executes on rejected handlers in the same order as the originating calls' do
        promise  = Promise.new

        expect do |block|
          promise.on_rejected { block.to_proc.call(1) }
          promise.on_rejected { block.to_proc.call(2) }
          promise.on_rejected { block.to_proc.call(3) }
          promise.reject(:error)
        end.to yield_successive_args(1, 2, 3)
      end

      it 'executes on rejected handlers after resolved' do
        promise = Promise.new
        expect do |block|
          promise.reject(:error)
          promise.on_rejected(&block)
        end.to yield_successive_args(:error)
      end

      it 'does not execute on fullfiled handlers if it has not been fullfiled' do
        promise = Promise.new
        expect do |block|
          promise.on_fullfiled(&block)
        end.to_not yield_with_args(:error)
      end

      it 'does not execute on rejected handlers if it has not been rejected' do
        promise = Promise.new
        expect do |block|
          promise.on_rejected(&block)
        end.to_not yield_with_args(:error)
      end

      it 'can not be rejected once it has been fulfilled' do
        promise = Promise.new
        expect do |block|
          promise.on_fullfiled(&block)
          promise.resolve(:foo)
          promise.on_rejected(&block)
          promise.reject(:error)
        end.to yield_successive_args(:foo)
      end

      it 'can not be fullfiled once it has been rejected' do
        promise = Promise.new
        expect do |block|
          promise.on_rejected(&block)
          promise.on_fullfiled(&block)
          promise.reject(:error)
          promise.resolve(:foo)
        end.to yield_successive_args(:error)
      end
    end

    describe '#on_fullfiled' do
      it 'throws an error when called with a non callable object' do
        promise = Promise.new
        expect { promise.on_fullfiled }.to raise_error(ArgumentError)
      end
    end

    describe '#on_rejected' do
      it 'throws an error when called with a non callable object' do
        promise = Promise.new
        expect { promise.on_fullfiled }.to raise_error(ArgumentError)
      end
    end

    describe '#then' do
      it 'adds on fullfiled handlers' do
        promise = Promise.new
        expect do |block|
          promise.then(on_fullfiled: block)
          promise.resolve(:foo)
        end.to yield_with_args(:foo)
      end

      it 'adds on rejected handlers' do
        promise = Promise.new
        expect do |block|
          promise.then(on_rejected: block)
          promise.reject(:error)
        end.to yield_with_args(:error)
      end

      it 'does not require both on fullfiled and on rejected handlers' do
        promise = Promise.new
        expect do |block|
          promise.then(on_rejected: block)
          promise.then(on_fullfiled: block)
          promise.reject(:error)
        end.to yield_with_args(:error)
      end
    end

    describe 'resolution procedure' do
      it 'adopts the given promise state when resolved with a promise'do
        promise_a = Promise.new
        promise_b = Promise.new

        expect do |block|
          promise_a.on_fullfiled(&block)
          promise_a.resolve(promise_b)
          promise_b.resolve(:foobar)
        end.to yield_with_args(:foobar)

        promise_a = Promise.new
        promise_b = Promise.new

        expect do |block|
          promise_a.on_rejected(&block)
          promise_a.resolve(promise_b)
          promise_b.reject(:foobar)
        end.to yield_with_args(:foobar)

        promise_a = Promise.new
        promise_b = Promise.new
      end
    end
  end
end
