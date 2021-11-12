require "procon_bypass_man/outbound/client"
require "procon_bypass_man/outbound/base_event_reporter"

class ProconBypassMan::ErrorReporter < ProconBypassMan::BaseEventReporter
  def self.report(body: )
    ProconBypassMan::Outbound::Client.new(
      path: path,
      server_picker: server_picker,
      retry_on_connection_error: false,
    ).post(body: body.full_message, event_type: :error,)
  end
end
