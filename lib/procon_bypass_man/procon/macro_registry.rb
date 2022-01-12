class ProconBypassMan::Procon::MacroRegistry
  class Macro
    attr_accessor :name, :steps

    def initialize(name: , steps: )
      self.name = name
      self.steps = steps
    end

    def next_step
      steps.shift
    end

    def finished?
      steps.empty?
    end

    def ongoing?
      !finished?
    end
  end

  PRESETS = {
    null: [],
  }

  def self.install_plugin(klass, steps: nil)
    if plugins[klass.to_s.to_sym]
      raise "#{klass} macro is already registered"
    end

    plugins[klass.to_s.to_sym] = ->{
      ProconBypassMan::Procon::ButtonCollection.normalize(steps || klass.steps)
    }
  end

  def self.load(name)
    steps = PRESETS[name] || plugins[name].call || raise("unknown macro")
    Macro.new(name: name, steps: steps.dup)
  end

  def self.reset!
    ProconBypassMan::ButtonsSettingConfiguration.instance.macro_plugins = {}
  end

  def self.plugins
    ProconBypassMan::ButtonsSettingConfiguration.instance.macro_plugins
  end

  reset!
end
