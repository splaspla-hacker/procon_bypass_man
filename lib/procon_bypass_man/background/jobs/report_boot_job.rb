class ProconBypassMan::ReportBootJob < ProconBypassMan::ReportBaseJob
  extend ProconBypassMan::HasExternalApiSetting

  # @param [String] body
  def self.perform(body)
    ProconBypassMan::HttpClient.new(
      path: path,
      pool_server: pool_server,
      retry_on_connection_error: true,
    ).post(body: body, event_type: :boot)
  end
end
