require "procon_bypass_man/outbound/client"

class ProconBypassMan::PressedButtonsReporter
  extend ProconBypassMan::Outbound::HasServerPicker

  PATH = "/api/pressed_buttons"

  def self.report(body: )
    ProconBypassMan::Outbound::Client.new(
      path: PATH,
      server_picker: server_picker,
    ).post(body: body)
  end

  def self.servers
    ProconBypassMan.config.internal_api_servers
  end
end