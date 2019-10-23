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
      response = BraspagRest::ProtectedCardRequest.save_card(access_token, self.inverse_attributes)
      if response.success?
        card_data = response.parsed_body['Card']
        self.card.number = card_data['Number']
        self.card.token  = response.parsed_body['TokenReference']
        self.card.expiration_date = card_data['ExpirationDate']
        self.card.holder = card_data['Holder']
        self.card.security_code = card_data['SecurityCode']
        return true
      else
        initialize_errors(response.parsed_body) and return false
      end
    end

    def initialize_errors(errors)
      @errors = errors.map { |error| { code: error['Code'], message: error['Message'] } }
    end
  end
end