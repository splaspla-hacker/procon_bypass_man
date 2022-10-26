class ProconBypassMan::DeviceConnection::ProconLess::ProconSimulator
  class ResponseBuilder
  end

  class ReportWatcher
    def intialize(watch_target)
    end

    # @return [Boolean]
    def complete?
    end
  end

  class ReportNegotiator
    def initialize
      @response_builder = ResponseBuilder.new
      @gadget = gadget
    end

    def execute
      loop do
        raw_data = read_from_gadget
        report_watcher.mark(raw_data: raw_data)
        write_to_gadget(@response_builder.build(raw_data: raw_data))
        break if report_watcher.complete?
      end
    end
  end

  def self.connect
    new.connect
  end

  # @raise [ProconBypassMan::SafeTimeout::Timeout]
  def connect
    pre_bypass_first
    pre_bypass
  end

  private

  def pre_bypass_first
    report_watcher = ReportWatcher.new([
      /^0000/,
      /^0000/,
      /^8005/,
      /^0000/,
      /^8001/,
      /^8002/,
      /^01000000000000000000033/,
      /^8004/,
    ])
    negotiator = ReportNegotiator.new(report_watcher: report_watcher)
    negotiator.execute
  end

  def pre_bypass
    report_watcher = ReportWatcher.new([
      "01-04",
      "02-",
      "04-00",
      "08-00",
      "10-00",
      "10-50",
      "10-80",
      "10-98",
      "10-10",
      "30-",
      "40-",
      "48-",
    ])
    negotiator = ReportNegotiator.new(report_watcher: report_watcher)
    negotiator.execute
  end
end
