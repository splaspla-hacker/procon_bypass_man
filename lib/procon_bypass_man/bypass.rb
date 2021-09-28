class ProconBypassMan::Bypass
  attr_accessor :gadget, :procon, :monitor
  attr_accessor :gadget_mutex, :procon_mutex

  def initialize(gadget: , procon: , monitor: )
    self.gadget_mutex = ::Thread::Mutex.new
    self.procon_mutex = ::Thread::Mutex.new
    self.gadget = gadget
    self.procon = procon
    self.monitor = monitor
  end

  # ゆっくりでいい
  def send_gadget_to_procon!
    monitor.record(:start_function)
    input = nil
    begin
      sleep(0.05)
      gadget_mutex.synchronize do
        input = self.gadget.read_nonblock(64)
      end
      ProconBypassMan.logger.debug { ">>> #{input.unpack("H*")}" }
    rescue IO::EAGAINWaitReadable
      monitor.record(:eagain_wait_readable_on_read)
      return if $will_terminate_token
      retry
    end

    begin
      procon_mutex.synchronize do
        self.procon.write_nonblock(input)
      end
    rescue IO::EAGAINWaitReadable
      monitor.record(:eagain_wait_readable_on_write)
      return
    rescue Errno::ETIMEDOUT => e
      # TODO まれに発生する再接続したい
      ProconBypassMan.cache.fetch(key: 'send_gadget_to_procon', expires_in: 30) do
        ProconBypassMan::ErrorReporter.report(body: e)
        nil
      end
      raise
    end

    monitor.record(:end_function)
  end

  def send_procon_to_gadget!
    monitor.record(:start_function)
    output = nil

    begin
      return if $will_terminate_token
      Timeout.timeout(1) do
        procon_mutex.synchronize do
          output = self.procon.read(64)
        end
        ProconBypassMan.logger.debug { "<<< #{output.unpack("H*")}" }
      end
    rescue Timeout::Error
      ProconBypassMan.logger.debug { "read timeout! do sleep. by send_procon_to_gadget!" }
      ProconBypassMan.error_logger.error { "read timeout! do sleep. by send_procon_to_gadget!" }
      monitor.record(:eagain_wait_readable_on_read)
      retry
    rescue IO::EAGAINWaitReadable
      ProconBypassMan.logger.debug { "EAGAINWaitReadable" }
      monitor.record(:eagain_wait_readable_on_read)
      sleep(0.005)
      retry
    end

    if defined?(@send_gadget_to_switch_queue)
      push_gadget_to_switch_queue(output)
    else
      start_send_gadget_to_switch_thread
      push_gadget_to_switch_queue(output)
    end
  end

  private

  def start_send_gadget_to_switch_thread
    @send_gadget_to_switch_queue = SizedQueue.new(1000)
    @send_gadget_to_switch_thread = Thread.new do
      while(data = @send_gadget_to_switch_queue.pop) do
        begin
          gadget_mutex.synchronize do
            self.gadget.write_nonblock(ProconBypassMan::Processor.new(data).process)
          end
        rescue IO::EAGAINWaitReadable
          monitor.record(:eagain_wait_readable_on_write)
          next
        end
        monitor.record(:end_function)
      end
    end
  end

  def push_gadget_to_switch_queue(output)
    @send_gadget_to_switch_queue.push(output)
  end
end
