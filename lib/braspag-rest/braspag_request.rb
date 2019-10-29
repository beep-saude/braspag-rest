module BraspagRest
 class BraspagRequest 
    class << self
      def execute_braspag_request(&block)
        gateway_response = block.call
        BraspagRest::Response.new(gateway_response).tap do |response|
          config.logger.info("[BraspagRest][Response] gateway_response: #{response.parsed_body}") if config.log_enabled?
        end
      rescue RestClient::ResourceNotFound => e
        # Explicitly message due to Rest Client RestClient::NotFound normalization:
        # https://github.com/rest-client/rest-client/blob/v2.0.0/lib/restclient/exceptions.rb#L90
        config.logger.error("[BraspagRest][Error] message: Resource Not Found, status: #{e.http_code}, body: #{e.http_body.inspect}") if config.log_enabled?
        raise
      rescue RestClient::RequestTimeout => e
        config.logger.error("[BraspagRest][Timeout] message: #{e.message}") if config.log_enabled?
        raise
      rescue RestClient::ExceptionWithResponse => e
        config.logger.warn("[BraspagRest][Error] message: #{e.message}, status: #{e.http_code}, body: #{e.http_body.inspect}") if config.log_enabled?
        BraspagRest::Response.new(e.response)
      rescue RestClient::Exception => e
        config.logger.error("[BraspagRest][Error] message: #{e.message}, status: #{e.http_code}, body: #{e.http_body.inspect}") if config.log_enabled?
        raise
      end

      def config
        @config ||= BraspagRest.config
      end
    end
  end
end