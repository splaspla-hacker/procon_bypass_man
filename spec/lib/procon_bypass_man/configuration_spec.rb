require "spec_helper"

describe ProconBypassMan::Configuration do
  before(:each) do
    ProconBypassMan.reset!
  end

  describe 'Loader' do
    describe '.load' do
      context '2回loadするとき' do
        class ::AMacroPlugin
          def self.name; :the_macro; end
          def self.steps; [:a, :b]; end
        end
        class AModePlugin
          def self.name; :foo; end
          def self.binaries; ['a']; end
        end
        after(:each) { first_setting&.close; second_setting&.close }
        let(:first_setting_content) do
          <<~EOH
          version: 1.0
          setting: |-
            install_macro_plugin(AMacroPlugin)
            install_mode_plugin(AModePlugin)
            prefix_keys_for_changing_layer [:zr, :r, :zl, :l]
            layer :up do
              flip :zr, if_pressed: :zr
            end
          EOH
        end
        let(:second_setting_content) do
          <<~EOH
          version: 1.0
          setting: |-
            install_macro_plugin(AMacroPlugin)
            install_mode_plugin(AModePlugin)
            prefix_keys_for_changing_layer [:a]
            layer :up do
              flip :b, if_pressed: :b
            end
          EOH
        end
        let(:first_setting) do
          require "tempfile"
          file = Tempfile.new(["", ".yml"])
          file.write first_setting_content
          file.seek 0
          file
        end
        let(:second_setting) do
          require "tempfile"
          file = Tempfile.new(["", ".yml"])
          file.write second_setting_content
          file.seek 0
          file
        end
        it '2回目の設定が設定されていること' do
          ProconBypassMan::Configuration::Loader.load(setting_path: first_setting.path)
          expect(ProconBypassMan::Configuration.instance.prefix_keys).to eq([:zr, :r, :zl, :l])
          expect(ProconBypassMan::Configuration.instance.layers[:up].flip_buttons).to eq(zr: { if_pressed: [:zr] })
          ProconBypassMan::Configuration::Loader.load(setting_path: second_setting.path)
          expect(ProconBypassMan::Configuration.instance.prefix_keys).to eq([:a])
          expect(ProconBypassMan::Configuration.instance.layers[:up].flip_buttons).to eq(b: { if_pressed: [:b] })
        end
      end
    end
  end

  describe '.configure' do
    context 'with setting_path' do
      after(:each) { setting&.close }
      let(:setting_content) do
        <<~EOH
          version: 1.0
          setting: |-
            prefix_keys_for_changing_layer [:zr, :r, :zl, :l]
            layer :up do
              flip :zr, if_pressed: :zr
            end
        EOH
      end
      let(:setting) do
        require "tempfile"
        file = Tempfile.new(["", ".yml"])
        file.write setting_content
        file.seek 0
        file
      end
      it do
        ProconBypassMan.configure(setting_path: setting.path)
        expect(ProconBypassMan::Configuration.instance.prefix_keys).to eq([:zr, :r, :zl, :l])
        expect(ProconBypassMan::Configuration.instance.layers[:up].flip_buttons).to eq(zr: { if_pressed: [:zr] })
        expect(ProconBypassMan::Configuration.instance.layers[:down].flips).to eq({})
        expect(ProconBypassMan::Configuration.instance.setting_path).to eq(setting.path)
      end
    end

    context 'with install macro plugin' do
      it do
        class AMacroPlugin
          def self.name; :the_macro; end
          def self.steps; [:a, :b]; end
        end
        ProconBypassMan.configure do
          install_macro_plugin(AMacroPlugin)
          layer :up do
            macro :the_macro, if_pressed: [:a, :y]
          end
        end
        expect(ProconBypassMan::Procon::MacroRegistry.plugins).to eq(the_macro: [:a, :b])
      end
    end
    context 'with install mode plugin' do
      it do
        class AModePlugin
          def self.name; :foo; end
          def self.binaries; ['a']; end
        end
        ProconBypassMan.configure do
          install_mode_plugin(AModePlugin)
          layer :up, mode: AModePlugin.name
        end
        expect(ProconBypassMan::Procon::ModeRegistry.plugins).to eq(foo: ['a'])
      end
    end
    context 'with macro' do
      it do
        ProconBypassMan.configure do
          layer :up do
            macro :fast_return, if_pressed: [:y, :b, :down]
          end
        end
      end
    end

    context 'with if_pressed' do
      it do
        ProconBypassMan.configure do
          layer :up do
            flip :l, if_pressed: [:y, :b], force_neutral: :y
          end
          layer :down
          layer :right
          layer :left
        end
        expect(ProconBypassMan::Configuration.instance.layers[:up].flip_buttons[:l]).to eq(if_pressed: [:y, :b], force_neutral: :y)
        expect(ProconBypassMan::Configuration.instance.layers[:up].flip_buttons.keys).to eq([:l])
      end
    end

    context 'with some mode' do
      it do
        class AModePlugin
          def self.name; :foo; end
          def self.binaries; ['a']; end
        end
        ProconBypassMan.configure do
          install_mode_plugin AModePlugin
          layer :up do
            flip :l, if_pressed: true
            flip :r, channel: 1
          end
          layer :down, mode: :manual do
            flip :r, if_pressed: [:zr, :zl]
          end
          layer :right, mode: :foo
          layer :left
        end
        expect(ProconBypassMan::Configuration.instance.layers[:up].flip_buttons[:l]).to eq(if_pressed: [:l])
        expect(ProconBypassMan::Configuration.instance.layers[:up].flip_buttons[:r]).to eq(if_pressed: false, channel: 1)
        expect(ProconBypassMan::Configuration.instance.layers[:up].flip_buttons.keys).to eq([:l, :r])
        expect(ProconBypassMan::Configuration.instance.layers[:up].mode).to eq(:manual)
        expect(ProconBypassMan::Configuration.instance.layers[:down].flip_buttons.keys).to eq([:r])
        expect(ProconBypassMan::Configuration.instance.layers[:down].flip_buttons[:r]).to eq(if_pressed: [:zr, :zl])
        expect(ProconBypassMan::Configuration.instance.layers[:down].mode).to eq(:manual)
        expect(ProconBypassMan::Configuration.instance.layers[:right].flip_buttons.keys).to eq([])
        expect(ProconBypassMan::Configuration.instance.layers[:right].mode).to eq(:foo)
        expect(ProconBypassMan::Configuration.instance.layers[:left].flip_buttons.keys).to eq([])
        expect(ProconBypassMan::Configuration.instance.layers[:left].mode).to eq(:manual)
      end
    end

    context 'has values' do
      it do
        ProconBypassMan.configure do
          layer :up do
            flip :l
            flip :r
          end
          layer :down do
            flip :r
          end
          layer :right
          layer :left
        end
        expect(ProconBypassMan::Configuration.instance.layers[:up].flip_buttons.keys).to eq([:l, :r])
        expect(ProconBypassMan::Configuration.instance.layers[:down].flip_buttons.keys).to eq([:r])
        expect(ProconBypassMan::Configuration.instance.layers[:right].flip_buttons.keys).to eq([])
        expect(ProconBypassMan::Configuration.instance.layers[:left].flip_buttons.keys).to eq([])
      end
    end

    context '全部空' do
      it do
        ProconBypassMan.configure do
          layer :up do
          end
          layer :down do
          end
          layer :right do
          end
          layer :left do
          end
        end
        expect(ProconBypassMan::Configuration.instance.layers[:up].flip_buttons.keys).to eq([])
        expect(ProconBypassMan::Configuration.instance.layers[:down].flip_buttons.keys).to eq([])
        expect(ProconBypassMan::Configuration.instance.layers[:right].flip_buttons.keys).to eq([])
        expect(ProconBypassMan::Configuration.instance.layers[:left].flip_buttons.keys).to eq([])
      end
    end

    describe 'prefix_keys_for_changing_layer' do
      it do
        ProconBypassMan.configure do
          prefix_keys_for_changing_layer [:zr]
        end
        expect(ProconBypassMan::Configuration.instance.prefix_keys).to eq([:zr])
      end
    end
  end
end
