module ProconBypassMan
  class ButtonsSettingConfiguration
    module Loader
      require 'digest/md5'

      def self.load(setting_path: )
        ProconBypassMan::ButtonsSettingConfiguration.switch_new_context(:validation) do |validation_instance|
          yaml = YAML.load_file(setting_path) or raise "読み込みに失敗しました"
          validation_instance.instance_eval(yaml["setting"])
          validator = Validator.new(validation_instance)
          if validator.valid?
            next
          else
            raise ProconBypassMan::CouldNotLoadConfigError, validator.errors
          end
        rescue SyntaxError
          raise ProconBypassMan::CouldNotLoadConfigError, "Rubyのシンタックスエラーです"
        rescue Psych::SyntaxError
          raise ProconBypassMan::CouldNotLoadConfigError, "yamlのシンタックスエラーです"
        end

        yaml = YAML.load_file(setting_path)
        ProconBypassMan::ButtonsSettingConfiguration.instance.setting_path = setting_path
        ProconBypassMan::ButtonsSettingConfiguration.instance.reset!
        ProconBypassMan.reset!

        case yaml["version"]
        when 1.0, nil
          ProconBypassMan::ButtonsSettingConfiguration.instance.instance_eval(yaml["setting"])
        else
          ProconBypassMan.logger.warn "不明なバージョンです。failoverします"
          ProconBypassMan::ButtonsSettingConfiguration.instance.instance_eval(yaml["setting"])
        end

        File.write(ProconBypassMan.digest_path, Digest::MD5.hexdigest(yaml["setting"]))

        ProconBypassMan::ButtonsSettingConfiguration.instance
      end

      def self.reload_setting
        self.load(setting_path: ProconBypassMan::ButtonsSettingConfiguration.instance.setting_path)
      end
    end
  end
end