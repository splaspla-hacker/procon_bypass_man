class ProconBypassMan::DeviceConnection::Command
  # @return [void]
  def self.execute!
    gadget, procon = ProconBypassMan::DeviceConnection::Executer.connect
  rescue ProconBypassMan::DeviceConnection::NotFoundProconError => e
    ProconBypassMan.logger.error e
    gadget&.close
    procon&.close
    raise ProconBypassMan::DeviceConnection::NotFoundProconError
  rescue ProconBypassMan::SafeTimeout::Timeout
    ProconBypassMan.logger.error "デバイスとの通信でタイムアウトが起きて接続ができませんでした。"
    gadget&.close
    procon&.close
    raise ProconBypassMan::EternalConnectionError
  end
end