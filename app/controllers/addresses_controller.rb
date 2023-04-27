class AddressesController < ApplicationController
  def show
    address = Address.find_by!(address: params[:id])
    transactions = Transaction.where(from_address: address.address).or(Transaction.where(to_address: address.address))

    response_data = {
      balance: address.cornlet_balance,
      transactions: transactions.map do |transaction|
        {
          amount: transaction.cornlet_amount,
          timestamp: transaction.created_at,
          toAddress: transaction.to_address
        }
      end
    }

    render json: response_data
  end
end
