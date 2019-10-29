require 'spec_helper'

describe BraspagRest::ProtectedCardRequest do
  let(:config) { YAML.load(File.read('spec/fixtures/configuration.yml'))['test'] }
  let(:logger) { double(info: nil) }
  let(:request) { spy }

  before(:each) do 
    BraspagRest.config do |configuration|
      configuration.config_file_path = 'spec/fixtures/configuration.yml'
      configuration.environment = 'test'
      configuration.logger = logger
    end
    allow(RestClient::Request).to receive(:new).and_return(request)
  end

  describe '.get_access_token' do 
    let(:access_token_url) { config['protected_card_auth_url'] + 'oauth2/token' }
    let(:authorization) { 'yJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjbGllbnRfbmFtZSI6IkJFRVAgU' }
    let(:headers) do
      {
        content_type: 'application/x-www-form-urlencoded',
        Authorization: "Basic #{authorization}",
      }
    end
    let(:params) {
      { grant_type: 'client_credentials' }
    }

    let(:gateway_response) do 
      double(
        code: 200, 
        body: {
          "access_token": "faSYkjfiod8ddJxFTU3vti_D0i0jqcw",
          "token_type": "bearer",
          "expires_in": 599
        }.to_json
      )
    end

    before(:each) do 
      allow(Base64).to receive(:strict_encode64).and_return(authorization)
    end

    context 'when a successful response' do 
      before(:each) do 
        allow(request).to receive(:execute).and_return(gateway_response)
      end

      it 'calls the auth token api to get access token' do 
        expect(RestClient::Request).to receive(:new).with(
          method: :post,
          url: access_token_url,
          payload: params,
          headers: headers
        )
        expect(request).to receive(:execute)
        described_class.get_access_token
      end

      it 'returns a valid access token' do 
        response = described_class.get_access_token
        expect(response).to equal(response)
      end
    end
    
    context 'when is a failure by access denied' do 
      let(:gateway_fail_response) do 
        double(
          code: 401, 
          body: { "Message" => 'Access denied'}.to_json
        )
      end
  
      before(:each) do 
        allow(request).to receive(:execute).and_return(gateway_fail_response)
      end
  
      it 'returns braspag failed response and log it as warning' do 
        response = described_class.get_access_token
        expect(response).not_to be_success
        expect(response.parsed_body).to eq({ "Message" => 'Access denied'})
      end
    end
  end

  describe '.save_card' do 
    let(:access_token) { 'faSYkjfiod8ddJxFTU3vti_D0i0jqcw' }
    let(:save_card_url) { config['protected_card_url'] + 'v1/Token' }
    let(:params) do 
      {
        "Alias":"5R2O404433YT",
          "Card": {
              "Number": "4551870000000183",
              "Holder": "Joao da Silva",
              "ExpirationDate": "12/2032",
              "SecurityCode": "123"
          }
      }
    end
    let(:headers) do 
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{access_token}",
        'MerchantId' => config['merchant_id']
      }
    end


    context  'when a successful response' do
      let(:gateway_response) do 
        double( 
          code: 200, 
          body: {
            "Alias": "5R2O4042YP",
            "TokenReference": "c2e0d46e-6a78-409b-9ad4-75bcb3985762",
            "ExpirationDate": "2021-12-31",
            "Card": {
                "Number": "************0183",
                "ExpirationDate": "12/2021",
                "Holder": "Joao da Silva",
                "SecurityCode": "***"
            },
            "Links": [
                {
                    "Method": "GET",
                    "Rel": "self",
                    "HRef": "https://cartaoprotegidoapisandbox.braspag.com.br/v1/Token/c2e0d46e-6a78-409b-9ad4-75bcb3985762"
                },
                {
                    "Method": "DELETE",
                    "Rel": "remove",
                    "HRef": "https://cartaoprotegidoapisandbox.braspag.com.br/v1/Token/c2e0d46e-6a78-409b-9ad4-75bcb3985762"
                },
                {
                    "Method": "PUT",
                    "Rel": "suspend",
                    "HRef": "https://cartaoprotegidoapisandbox.braspag.com.br/v1/Token/c2e0d46e-6a78-409b-9ad4-75bcb3985762/suspend"
                }
            ]
          }.to_json
        )
      end

      before(:each) do 
        allow(request).to receive(:execute).and_return(gateway_response)
      end
      
      it 'saves the card' do 
        expect(RestClient::Request).to receive(:new).with(
          method: :post,
          url: save_card_url,
          payload: params.to_json,
          headers: headers
        )
        expect(request).to receive(:execute)
        described_class.save_card(access_token, params)
      end
    end 
  
  end
end
