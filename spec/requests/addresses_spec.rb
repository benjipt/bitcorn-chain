# spec/requests/addresses_spec.rb
require 'rails_helper'

RSpec.describe 'Addresses', type: :request do
  let!(:address) { create(:address, address: 'test_address', cornlet_balance: 10_000_000) }
  let!(:address2) { create(:address, address: 'test_address_2', cornlet_balance: 0) }
  let!(:address3) { create(:address, address: 'test_address_3', cornlet_balance: 40_000_000) }
  let!(:transaction1) { create(:transaction, from_address: address, to_address: address2, cornlet_amount: 5_000_000) }
  let!(:transaction2) { create(:transaction, from_address: address3, to_address: address2, cornlet_amount: 4_000_000) }

  describe 'GET /addresses/:id' do
    context 'when the address exists' do
      before { get "/addresses/#{address.address}" }

      it 'returns the address balance and transactions' do
        json = JSON.parse(response.body)
        expect(json).not_to be_empty
        expect(json['balance']).to eq(10.0)
        expect(json['transactions'].size).to eq(1)
        expect(json['transactions'][0]['amount']).to eq(5.0)
        expect(json['transactions'][0]['toAddress']).to eq('test_address_2')
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the address does not exist' do
      before { get '/addresses/unknown_address' }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns an error message' do
        expect(response.body).to match("Address not found")
      end
    end

    context 'when the address is in mixed case' do
      before { get "/addresses/#{address.address.upcase}" }

      it 'converts the address to lower case and returns the correct data' do
        json = JSON.parse(response.body)
        expect(json).not_to be_empty
        expect(json['balance']).to eq(10.0)
        expect(json['transactions'].size).to eq(1)
        expect(json['transactions'][0]['amount']).to eq(5.0)
        expect(json['transactions'][0]['toAddress']).to eq('test_address_2')
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end
end
