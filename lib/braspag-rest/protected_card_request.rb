module BraspagRest
  class ProtectedCardRequest
    class << self
      ACCESS_TOKEN_ENDPOINT = 'oauth2/token' 
      CREATE_TOKEN_ENDPOINT = '/v1/Token'
      
      def get_access_token
        config.logger.info("[BraspagRest][GetAccessToken] endpoint: #{access_token_url} - Basic #{config.client_id}:#{config.client_secret}") if config.log_enabled?
        authorization = Base64.strict_encode64("#{config.client_id}:#{config.client_secret}")
        execute_braspag_request do 
          RestClient::Request.execute(
            method: :post,
            url: access_token_url,
            headers: default_access_token_headers.merge('Authorization' => "Basic #{authorization}"),
            timeout: config.request_timeout
          )
        end

      end

      private

      def access_token_url
        config.protected_card_url + ACCESS_TOKEN_ENDPOINT 
      end

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
  
      def default_access_token_headers
        {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'grant_type' => 'client_credentials'
        }
      end

      def config
        @config ||= BraspagRest.config
      end
    end
  end
end