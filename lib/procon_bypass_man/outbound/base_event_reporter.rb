require "procon_bypass_man/outbound/client"

class ProconBypassMan::BaseEventReporter
  extend ProconBypassMan::Outbound::HasServerPicker

  def self.servers
    ProconBypassMan.config.api_servers
  end

  def self.path
    "/api/events"
  end
end
