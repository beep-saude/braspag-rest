module BraspagRest
  class ProtectedCard < Hashie::IUTrash
    include Hashie::Extensions::Coercion

    attr_reader :errors 

    property :alias, from: 'Alias'
    property :card, from: 'Card', with: ->(values) { BraspagRest::CreditCard.new(values)}

    coerce_key :card, BraspagRest::CreditCard

    def save
      response = BraspagRest::ProtectedCardRequest.get_access_token
      if response.success?
        access_token = response.parsed_body['access_token']
        return save_card(access_token)
      else
        initialize_errors(response.parsed_body) and return false
      end
    end

    private 

    def save_card(access_token)
      attributes = {
        'Alias': self.alias, 
        'Card': {
          'Number': self.card.number,
          'Holder': self.card.holder, 
          'ExpirationDate': self.card.expiration_date,
          'SecurityCode': self.card.security_code
        }
      }
      response = BraspagRest::ProtectedCardRequest.save_card(access_token, attributes)
      if response.success?
        map_to_card(response.parsed_body)
        return true
      else
        initialize_errors(response.parsed_body) and return false
      end
    end

    def initialize_errors(errors)
      @errors = errors.map { |error| { code: error.dig('Code'), message: error.dig('Message') } }
    end

    private 

    def map_to_card(response_body)
      card_data = response_body['Card']
      self.card.number = card_data['Number']
      self.card.token  = response_body['TokenReference']
      self.card.expiration_date = card_data['ExpirationDate']
      self.card.holder = card_data['Holder']
      self.card.security_code = card_data['SecurityCode']
    end
  end
end