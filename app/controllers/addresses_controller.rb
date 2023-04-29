class AddressesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def show
    address = Address.find_by!(address: params[:id].downcase)
    transactions = Transaction.where(from_address: address.address).or(Transaction.where(to_address: address.address))

    response_data = {
      balance: address.cornlet_balance.to_f / 1_000_000.0,
      transactions: transactions.map do |transaction|
        {
          amount: transaction.cornlet_amount.to_f / 1_000_000.0,
          timestamp: transaction.created_at,
          toAddress: transaction.to_address.address,
        }
      end
    }

    render json: response_data
  end

  private

  def record_not_found
    render json: { error: 'Address not found' }, status: :not_found
  end
end
