class ProconBypassMan::Bypass::ConcurrentBypassExecutor
  include Singleton

  class Executor
    def initialize(queue: )
      @thread = Thread.new do
        loop do
          if(task = queue.pop)
            task[:block].call(task[:bypass])
          else
            break
          end
        end
      end
    end
  end

  attr_reader :queue

  def initialize
    @queue = Queue.new
    @pool = TREHAD_SIZE.times.map { Executor.new(queue: @queue) }
  end

  TREHAD_SIZE = 3

  # TODO Threadで起きた例外をスローしたい
  def self.execute(bypass: , &block)
    TREHAD_SIZE.times do
      instance.queue.push(bypass: bypass, block: block)
    end
  end
end