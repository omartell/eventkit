require 'eventkit'

module Eventkit
  RSpec.describe Promise do
    let(:promise) { Promise.new }

    describe 'is in a pending, fullfiled or rejected state' do
      it 'executes on fullfiled handlers when resolved' do
        expect do |block|
          promise.on_fullfiled(&block)
          promise.on_fullfiled(&block)
          promise.on_fullfiled(&block)
          promise.resolve(:foo)
        end.to yield_successive_args(:foo, :foo, :foo)
      end

      it 'executes on fullfiled handlers after resolved' do
        expect do |block|
          promise.resolve(:foo)
          promise.on_fullfiled(&block)
        end.to yield_successive_args(:foo)
      end

      it 'only executes on fullfiled handlers once even if resolved multiple times' do
        expect do |block|
          promise.on_fullfiled(&block)
          promise.resolve(:foo)
          promise.resolve(:foo)
        end.to yield_control.once
      end

      it 'executes on fullfiled handlers in the same order as the originating calls' do
        expect do |block|
          promise.on_fullfiled { block.to_proc.call(1) }
          promise.on_fullfiled { block.to_proc.call(2) }
          promise.on_fullfiled { block.to_proc.call(3) }
          promise.resolve(:foo)
        end.to yield_successive_args(1, 2, 3)
      end

      it 'executes on rejected handlers when rejected' do
        expect do |block|
          promise.on_rejected(&block)
          promise.on_rejected(&block)
          promise.on_rejected(&block)
          promise.reject(:error)
        end.to yield_successive_args(:error, :error, :error)
      end

      it 'only executes on rejected handlers once event if rejected multiple times' do
        expect do |block|
          promise.on_rejected(&block)
          promise.reject(:error)
          promise.reject(:error)
        end.to yield_control.once
      end

      it 'executes on rejected handlers in the same order as the originating calls' do
        expect do |block|
          promise.on_rejected { block.to_proc.call(1) }
          promise.on_rejected { block.to_proc.call(2) }
          promise.on_rejected { block.to_proc.call(3) }
          promise.reject(:error)
        end.to yield_successive_args(1, 2, 3)
      end

      it 'executes on rejected handlers even when it has been already rejected' do
        expect do |block|
          promise.reject(:error)
          promise.on_rejected(&block)
        end.to yield_successive_args(:error)
      end

      it 'does not execute on fullfiled handlers if it has not been fullfiled' do
        expect do |block|
          promise.on_fullfiled(&block)
        end.to_not yield_with_args(:error)
      end

      it 'does not execute on rejected handlers if it has not been rejected' do
        expect do |block|
          promise.on_rejected(&block)
        end.to_not yield_with_args(:error)
      end

      it 'can not be rejected once it has been fulfilled' do
        expect do |block|
          promise.on_fullfiled(&block)
          promise.resolve(:foo)
          promise.on_rejected(&block)
          promise.reject(:error)
        end.to yield_successive_args(:foo)
      end

      it 'can not be fullfiled once it has been rejected' do
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
        expect { promise.on_fullfiled }.to raise_error(TypeError)
      end
    end

    describe '#on_rejected' do
      it 'throws an error when called with a non callable object' do
        expect { promise.on_fullfiled }.to raise_error(TypeError)
      end
    end

    describe '#then' do
      it 'adds on fullfiled handlers' do
        expect do |block|
          promise.then(block)
          promise.resolve(:foo)
        end.to yield_with_args(:foo)
      end

      it 'adds on rejected handlers' do
        expect do |block|
          promise.then(nil, block)
          promise.reject(:error)
        end.to yield_with_args(:error)
      end

      it 'does not require both on fullfiled and on rejected handlers' do
        expect do |block|
          promise.then(nil, block)
          promise.then(block)
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
      end

      it 'passes over the value from on fullfiled to the returned promise' do
        expect do |block|
          promise
          .then(-> (value) {
                  block.to_proc.call(value + 1)
                  value + 1
                })
          .then(-> (value) {
                  block.to_proc.call(value + 5)
                  value + 5
                })
          .then(-> (value) {
                  block.to_proc.call(value + 10)
                  value + 10
                })
          promise.resolve(1)
        end.to yield_successive_args(2, 7, 17)
      end

      it 'passes over the value from on rejected to the returned promise' do
        expect do |block|
          promise
          .then(nil, -> (reason) {
                  block.to_proc.call('bar')
                  'bar'
                })
          .then(-> (reason) {
                  block.to_proc.call('baz')
                  'baz'
                })
          .then(-> (reason) {
                  block.to_proc.call('zoo')
                  'zoo'
                })
          promise.reject('foo')
        end.to yield_successive_args('bar', 'baz', 'zoo')
      end

      it 'rejects the returned promise when on fullfiled throws an exception' do
        new_promise = promise.then(-> (value) { fail ArgumentError })

        promise.resolve('foobar')

        expect(new_promise).to be_rejected
        expect(new_promise.reason).to be_an_instance_of(ArgumentError)
      end

      it 'rejects the returned promise when on rejected throws an exception' do
        new_promise = promise
                      .then(-> (value) { fail ArgumentError })
                      .then(nil, -> (value) { fail NoMethodError })

        promise.resolve('foobar')

        expect(new_promise).to be_rejected
        expect(new_promise.reason).to be_an_instance_of(NoMethodError)
      end

      it 'fullfills the returned promise with the same value when on fullfiled is not a function' do
        new_promise = promise.then(nil, -> { })

        promise.resolve(:foo)

        expect(new_promise.value).to eq(:foo)
      end

      it 'rejects the returned promise with the same reason when on rejected is not a function' do
        new_promise = promise.then(-> { }, nil)

        promise.reject(:error)

        expect(new_promise.reason).to eq(:error)
      end
    end
  end
end

