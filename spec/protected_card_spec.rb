require 'spec_helper'

describe BraspagRest::ProtectedCard do
  let(:card_data) do 
    {
      alias: '5R2O4042YP',
      card: {
        number: '4551870000000183',
        holder: 'Joao da Silva',
        expiration_date: '12/2021',
        security_code: '123',
        brand: 'Visa'
      }
    }    
  end
  let(:protected_card) { BraspagRest::ProtectedCard.new(card_data)}

  describe ".new" do 
  
    it 'receives a hash and creates an instance of ProtectedCard with properties mapped' do 
      protected_card = BraspagRest::ProtectedCard.new(card_data)
      expect(protected_card.alias).to eq('5R2O4042YP')
      expect(protected_card.card).to_not be_nil
      expect(protected_card.card.number).to eq('4551870000000183')
      expect(protected_card.card.holder).to eq('Joao da Silva')
      expect(protected_card.card.expiration_date).to eq('12/2021')
      expect(protected_card.card.security_code).to eq('123')
      expect(protected_card.card.brand).to eq('Visa')
    end
  
  end

  describe "#save" do
    
    context "when the gateway returns a sucessful response" do 
      let(:token_parsed_body) do 
        {
          "access_token" => "faSYkjfiod8ddJxFTU3vti_xD0i0jqcw",
          "token_type" => "bearer",
          "expires_in" => 599
        }
      end

      let(:save_parsed_body) do 
        {
          "Alias" => "5R2O4042YP",
          "TokenReference" => "c2e0d46e-6a78-409b-9ad4-75bcb3985762",
          "ExpirationDate" => "2021-12-31",
          "Card" => {
              "Number" => "************0183",
              "ExpirationDate" => "12/2021",
              "Holder" => "Joao da Silva",
              "SecurityCode" => "***"
          },
          "Links" => [
              {
                  "Method" => "GET",
                  "Rel" => "self",
                  "HRef" => "https:/cartaoprotegidoapisandbox.braspag.com.br/v1/Token/c2e0d46e-6a78-409b-9ad4-75bcb3985762"
              },
              {
                  "Method" => "DELETE",
                  "Rel" => "remove",
                  "HRef" => "https://cartaoprotegidoapisandbox.braspag.com.br/v1/Token/c2e0d46e-6a78-409b-9ad4-75bcb3985762"
              },
              {
                  "Method" => "PUT",
                  "Rel" => "suspend",
                  "HRef" => "https://cartaoprotegidoapisandbox.braspag.com.br/v1/Token/c2e0d46e-6a78-409b-9ad4-75bcb3985762/suspend"
              }
          ]
      }
      end

      let(:token_response) { double(success?: true, parsed_body: token_parsed_body) }
      let(:save_response) {  double(success?: true, parsed_body: save_parsed_body) }

      before(:each) do 
        allow(BraspagRest::ProtectedCardRequest).to receive(:get_access_token).and_return(token_response)
        allow(BraspagRest::ProtectedCardRequest).to receive(:save_card).and_return(save_response)
      end

      it 'returns true and fills the credit card object with the return' do 
        expect(protected_card.save).to be_truthy
        expect(protected_card.card.number).to eq("************0183")
        expect(protected_card.card.expiration_date).to eq('12/2021')
        expect(protected_card.card.token).to eq('c2e0d46e-6a78-409b-9ad4-75bcb3985762')
      end
    end

    context 'when the gateway returns a failure' do
      let(:token_parsed_body) do 
        [{'Code' => 401, 'Message' =>'Access denied'}]
      end
      let(:save_parsed_body) do 
        [{'Code' => 'CP903', 'Message' => 'Token alias already exists'}]
      end

      context 'it fails to get the access token' do 
        let(:token_response) { double(success?: false, parsed_body: token_parsed_body) }
        
        before(:each) do 
          allow(BraspagRest::ProtectedCardRequest).to receive(:get_access_token).and_return(token_response)
        end

        it 'returns false' do 
          expect(protected_card.save).to be_falsey
        end

        it 'fills the errors attribute with the access code message' do 
          protected_card.save
          expect(protected_card.errors).to eq([{code: 401, message: 'Access denied'}])
        end
      end 

      context 'it fails to save the card' do 
        let(:token_parsed_body) do 
          {
            "access_token" => "faSYkjfiod8ddJxFTU3vti_xD0i0jqcw",
            "token_type" => "bearer",
            "expires_in" => 599
          }
        end
        let(:token_response) { double(success?: true, parsed_body: token_parsed_body) }
        let(:save_response)  { double(success?: false, parsed_body: save_parsed_body)}

        before(:each) do 
          allow(BraspagRest::ProtectedCardRequest).to receive(:get_access_token).and_return(token_response)
          allow(BraspagRest::ProtectedCardRequest).to receive(:save_card).and_return(save_response)
        end
        
        it 'returns false' do 
          expect(protected_card.save).to be_falsey
        end
        it 'fills the errors attribute' do 
          protected_card.save
          expect(protected_card.errors).to eq([{code: 'CP903', message: 'Token alias already exists'}])
        end
      end
    end 
  end 

end