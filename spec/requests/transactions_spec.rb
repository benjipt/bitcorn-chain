# frozen_string_literal: true

# spec/requests/transactions_spec.rb
require 'rails_helper'

RSpec.describe 'Transactions', type: :request do
  let!(:from_address) { create(:address, address: 'from_address', cornlet_balance: 10_000_000) }
  let!(:to_address) { create(:address, address: 'to_address', cornlet_balance: 0) }

  describe 'POST /transactions' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          transaction: {
            fromAddress: 'from_address',
            toAddress: 'to_address',
            amount: '4'
          }
        }
      end

      it 'creates a new transaction' do
        expect do
          post transactions_path, params: valid_params, as: :json
        end.to change(Transaction, :count).by(1)
      end

      it 'returns a success response and a success message' do
        post transactions_path, params: valid_params, as: :json
        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to eq('status' => 'success', 'message' => 'Transaction created successfully')
      end

      it 'updates the from_address and to_address cornlet_balance' do
        post transactions_path, params: valid_params, as: :json
        expect(from_address.reload.cornlet_balance).to eq(6_000_000)
        expect(to_address.reload.cornlet_balance).to eq(4_000_000)
      end

      it 'creates a transaction with the correct cornlet_amount' do
        post transactions_path, params: valid_params, as: :json
        expect(Transaction.last.cornlet_amount).to eq(4_000_000)
      end

      it 'saves the new to_address in lowercase to addresses table' do
        uppercase_to_address_params = {
          transaction: {
            fromAddress: 'from_address',
            toAddress: 'NEW_ADDRESS',
            amount: '1'
          }
        }

        expect do
          post transactions_path, params: uppercase_to_address_params, as: :json
        end.to change(Address, :count).by(1)

        created_address = Address.find_by(address: 'new_address')
        expect(created_address).not_to be_nil
        expect(created_address.address).to eq('new_address')
      end
    end

    context 'with insufficient balance' do
      let(:insufficient_balance_params) do
        {
          transaction: {
            fromAddress: 'from_address',
            toAddress: 'to_address',
            amount: '20'
          }
        }
      end

      it 'does not create a new transaction' do
        expect do
          post transactions_path, params: insufficient_balance_params, as: :json
        end.not_to change(Transaction, :count)
      end

      it 'returns an unprocessable_entity response with an insufficient balance error message' do
        post transactions_path, params: insufficient_balance_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq('error' => 'insufficient balance')
      end
    end

    context 'with missing fromAddress' do
      let(:missing_from_address_params) do
        {
          transaction: {
            toAddress: 'to_address',
            amount: '4'
          }
        }
      end

      it 'does not create a new transaction' do
        expect do
          post transactions_path, params: missing_from_address_params, as: :json
        end.not_to change(Transaction, :count)
      end

      it 'returns an unprocessable_entity response with a missing fromAddress error message' do
        post transactions_path, params: missing_from_address_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq('error' => 'fromAddress is required')
      end
    end

    context 'with missing toAddress' do
      let(:missing_to_address_params) do
        {
          transaction: {
            fromAddress: 'from_address',
            amount: '4'
          }
        }
      end

      it 'does not create a new transaction' do
        expect do
          post transactions_path, params: missing_to_address_params, as: :json
        end.not_to change(Transaction, :count)
      end

      it 'returns an unprocessable_entity response with a missing toAddress error message' do
        post transactions_path, params: missing_to_address_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq('error' => 'toAddress is required')
      end
    end

    context 'with missing amount' do
      let(:missing_amount_params) do
        {
          transaction: {
            fromAddress: 'from_address',
            toAddress: 'to_address'
          }
        }
      end

      it 'does not create a new transaction' do
        expect do
          post transactions_path, params: missing_amount_params, as: :json
        end.not_to change(Transaction, :count)
      end

      it 'returns an unprocessable_entity response with a missing amount error message' do
        post transactions_path, params: missing_amount_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq('error' => 'Amount is required')
      end
    end

    context 'with amount less than or equal to 0' do
      let(:negative_amount_params) do
        {
          transaction: {
            fromAddress: 'from_address',
            toAddress: 'to_address',
            amount: '-1'
          }
        }
      end
      let(:zero_amount_params) do
        {
          transaction: {
            fromAddress: 'from_address',
            toAddress: 'to_address',
            amount: '0'
          }
        }
      end

      it 'does not create a new transaction' do
        expect do
          post transactions_path, params: negative_amount_params, as: :json
        end.not_to change(Transaction, :count)
        expect do
          post transactions_path, params: zero_amount_params, as: :json
        end.not_to change(Transaction, :count)
      end

      it 'returns an unprocessable_entity response with an amount less than 0 error message' do
        post transactions_path, params: negative_amount_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq('error' => 'Amount should be greater than 0')

        post transactions_path, params: zero_amount_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq('error' => 'Amount should be greater than 0')
      end
    end
  end
end
