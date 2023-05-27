# frozen_string_literal: true

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
        json = response.parsed_body
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
        expect(response.body).to match('Address not found')
      end
    end

    context 'when the address is in mixed case' do
      before { get "/addresses/#{address.address.upcase}" }

      it 'converts the address to lower case and returns the correct data' do
        json = response.parsed_body
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

  describe 'POST /addresses' do
    context 'when the address does not exist' do
      before { post '/addresses', params: { address: 'new_address' } }

      it 'creates a new address and returns status code 201' do
        expect(response).to have_http_status(201)
        expect(Address.find_by(address: 'new_address')).not_to be_nil
      end

      it 'has an initial balance of 100_000_000' do
        expect(Address.find_by(address: 'new_address').cornlet_balance).to eq(100_000_000)
      end
    end

    context 'when the address already exists' do
      before { post '/addresses', params: { address: address.address } }

      it 'returns an error message and status code 409' do
        expect(response).to have_http_status(409)
        expect(response.body).to match("User: #{address.address} already exists, please sign in instead")
      end
    end

    context 'when the id parameter is blank' do
      before { post '/addresses', params: { address: '' } }

      it 'returns an error message and status code 422' do
        expect(response).to have_http_status(422)
        expect(response.body).to match('Invalid address')
      end
    end

    let!(:seed_address) { create(:address, address: ENV.fetch('SEED_ADDRESS', nil), cornlet_balance: 1_000_000_000) }

    context 'when the seed address is not found' do
      before do
        Address.find_by(address: ENV.fetch('SEED_ADDRESS', nil)).destroy
        post '/addresses', params: { address: 'new_address_without_seed' }
      end

      it 'returns an error message and status code 500' do
        expect(response).to have_http_status(500)
        expect(response.body).to match('Could not find seed address. Unable to create a new user at this time.')
      end
    end
  end
end
