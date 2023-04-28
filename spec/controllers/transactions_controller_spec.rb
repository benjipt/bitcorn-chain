require 'rails_helper'

RSpec.describe TransactionsController, type: :controller do
  let(:satoshi) { Address.create(address: 'satoshi kozuka', cornlet_balance: 100_000_000_000_000) }
  let!(:from_address) { create(:address, address: 'from_address', cornlet_balance: 10000) }
  let!(:to_address) { create(:address, address: 'to_address', cornlet_balance: 0) }

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          transaction: {
            from_address: satoshi.address,
            to_address: 'test',
            amount: 1000000
          }
        }
      end

      it 'creates a new transaction' do
        expect {
          post :create, params: valid_params
        }.to change(Transaction, :count).by(1)
      end

      it 'returns a success status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      context 'with insufficient cornlet_balance' do
        let(:insufficient_balance_params) do
          {
            transaction: {
              from_address: satoshi.address,
              to_address: 'test',
              amount: satoshi.cornlet_balance + 1
            }
          }
        end

        it 'does not create a new transaction' do
          expect {
            post :create, params: insufficient_balance_params
          }.not_to change(Transaction, :count)
        end

        it 'returns an unprocessable entity status' do
          post :create, params: insufficient_balance_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with missing from_address' do
        let(:missing_from_address_params) do
          {
            transaction: {
              to_address: 'test',
              amount: 1000000
            }
          }
        end

        it 'does not create a new transaction' do
          expect {
            post :create, params: missing_from_address_params
          }.not_to change(Transaction, :count)
        end

        it 'returns an unprocessable entity status' do
          post :create, params: missing_from_address_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with missing to_address' do
        let(:missing_to_address_params) do
          {
            transaction: {
              from_address: satoshi.address,
              amount: 1000000
            }
          }
        end

        it 'does not create a new transaction' do
          expect {
            post :create, params: missing_to_address_params
          }.not_to change(Transaction, :count)
        end

        it 'returns an unprocessable entity status' do
          post :create, params: missing_to_address_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with snake_case payload' do
        it 'creates a transaction successfully' do
          expect {
            post :create, params: { transaction: { from_address: 'from_address', to_address: 'to_address', amount: 1000 } }
          }.to change(Transaction, :count).by(1)
  
          expect(response).to have_http_status(:created)
        end
      end
  
      context 'with camelCase payload' do
        it 'creates a transaction successfully' do
          expect {
            post :create, params: { transaction: { fromAddress: 'from_address', toAddress: 'to_address', amount: 1000 } }
          }.to change(Transaction, :count).by(1)
  
          expect(response).to have_http_status(:created)
        end
      end
    end
  end
end
