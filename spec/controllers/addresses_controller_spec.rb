require 'rails_helper'

RSpec.describe AddressesController, type: :controller do
  let!(:address) { create(:address, address: 'test_address', cornlet_balance: 10000) }
  let!(:address2) { create(:address, address: 'test_address_2', cornlet_balance: 0) }
  let!(:address3) { create(:address, address: 'test_address_3', cornlet_balance: 4000) }
  let!(:transaction1) { create(:transaction, from_address: address, to_address: address2, cornlet_amount: 5000) }
  let!(:transaction2) { create(:transaction, from_address: address3, to_address: address2, cornlet_amount: 4000) }

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: 'test_address' }
      expect(response).to be_successful
    end

    it 'returns the correct address balance and transactions' do
      get :show, params: { id: 'test_address' }
      parsed_response = JSON.parse(response.body)
    
      expect(parsed_response['balance']).to eq(10000)
      expect(parsed_response['transactions'].size).to eq(1)
      expect(parsed_response['transactions'][0]['amount']).to eq(5000)
      expect(parsed_response['transactions'][0]['toAddress']['address']).to eq('test_address_2')
    end
  end
end
