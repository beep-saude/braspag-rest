
module BraspagRest
  class ProtectedCardRequest
    class << self
      ACCESS_TOKEN_ENDPOINT = 'oauth2/token' 
      CREATE_TOKEN_ENDPOINT = 'v1/Token'
      
      def get_access_token
        config.logger.info("[BraspagRest][GetAccessToken] endpoint: #{access_token_url} - Basic #{config.client_id}:#{config.client_secret}") if config.log_enabled?
        authorization = Base64.strict_encode64("#{config.client_id}:#{config.client_secret}")
        BraspagRequest.execute_braspag_request do
          RestClient::Request.new({
            method: :post,
            url: access_token_url,
            payload: {  grant_type: 'client_credentials' },
            headers: {
              content_type: 'application/x-www-form-urlencoded',
              Authorization: "Basic #{authorization}",
            }
          }).execute
        end
      end

      def save_card(access_token, attributes)
        config.logger.info("[BraspagRest][SaveCard] endpoint: #{create_token_url} - #{access_token}") if config.log_enabled?
        BraspagRequest.execute_braspag_request do
          RestClient::Request.new({
            method: :post,
            url: create_token_url,
            payload: attributes.to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => "Bearer #{access_token}",
              'MerchantId' => config.merchant_id
            }
          }).execute
        end
      end

      private

      def access_token_url
        config.protected_card_auth_url + ACCESS_TOKEN_ENDPOINT 
      end

      def create_token_url
        config.protected_card_url + CREATE_TOKEN_ENDPOINT
      end

      def config
        BraspagRequest.config
      end
    end
  end
end