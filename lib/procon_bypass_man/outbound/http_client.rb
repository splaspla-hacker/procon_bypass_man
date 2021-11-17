module ProconBypassMan
  module Outbound
    class HttpClient
      class HttpRequest
        def self.request!(uri: , hostname: , body: , device_id: , session_id: nil, event_type: )
          @uri = uri
          @http = Net::HTTP.new(uri.host, uri.port)
          @http.use_ssl = uri.scheme === "https"
          @params = {
            hostname: hostname,
            event_type: event_type,
            session_id: session_id,
            device_id: device_id,
          }.merge(body)
          @http.post(
            @uri.path,
            @params.to_json,
            { "Content-Type" => "application/json" },
          )
        end
      end

      def initialize(path: , server_picker: , retry_on_connection_error: false)
        @path = path
        @server_picker = server_picker
        @hostname = `hostname`.chomp
        @retry_on_connection_error = retry_on_connection_error
      end

      def post(body: , event_type: )
        if @server_picker.server.nil?
          ProconBypassMan.logger.info('送信先が未設定なのでスキップしました')
          return
        end
        if body.is_a?(Hash)
          body = { body: body, event_type: event_type }
        else
          body = { body: { value: body, event_type: event_type } }
        end
        session_id = ProconBypassMan.session_id
        device_id = ProconBypassMan.device_id

        response = HttpRequest.request!(
          uri: URI.parse("#{@server_picker.server}#{@path}"),
          hostname: @hostname,
          device_id: device_id,
          session_id: session_id,
          body: body,
          event_type: event_type,
        )
        case response.code
        when /^200/
          return
        else
          @server_picker.next!
          ProconBypassMan.logger.error("200以外(#{response.code})が帰ってきました. #{response.body}")
        end
      rescue SocketError => e
        ProconBypassMan.logger.error("error in outbound module: #{e}")
        if @retry_on_connection_error
          sleep(10)
          retry
        end
      rescue => e
        puts e
        ProconBypassMan.logger.error("error in outbound module: #{e}")
      end
    end
  end
end