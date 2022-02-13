class ProconBypassMan::BypassMode
  TYPE_NORMAL = :normal
  TYPE_AGGRESSIVE = :aggressive
  TYPES = [TYPE_NORMAL, TYPE_AGGRESSIVE]

  DEFAULT_GADGET_TO_PROCON_INTERVAL = 0.5

  attr_accessor :mode, :gadget_to_procon_interval

  def self.default_value
    new(
      mode: TYPE_NORMAL,
      gadget_to_procon_interval: DEFAULT_GADGET_TO_PROCON_INTERVAL,
    )
  end

  def initialize(mode: , gadget_to_procon_interval: )
    @mode = mode.to_sym
    @gadget_to_procon_interval = gadget_to_procon_interval
  end
end