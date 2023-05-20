# addresses_controller.rb
class SeedAddressNotFoundError < StandardError; end

class AddressesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def show
    address = Address.find_by!(address: params[:id].downcase)
    transactions = Transaction.where(from_address: address.address).or(Transaction.where(to_address: address.address))

    response_data = {
      balance: address.cornlet_balance.to_f / 1_000_000.0,
      transactions: transactions.map do |tx|
        {
          amount: tx.cornlet_amount.to_f / 1_000_000.0,
          timestamp: tx.created_at,
          toAddress: tx.to_address.address,
        }
      end
    }

    render json: response_data
  end

  def create
    return render json: { error: 'Invalid address' }, status: :unprocessable_entity if params[:address].blank?

    Address.transaction do
      new_address = Address.find_or_initialize_by(address: params[:address].downcase)

      satoshi_address = Address.find_by(address: 'satoshi kozuka')
      if satoshi_address.nil?
        render json: { error: 'Could not find seed address. Unable to create a new user at this time.' }, status: :unprocessable_entity
        return
      end

      if new_address.new_record? # Check if the record is new

        # Create a transaction from satoshi to the new address to seed the new address with 100 bitcorns
        transaction = Transaction.new(
          from_address: satoshi_address,
          to_address: new_address,
          cornlet_amount: 100 * 1_000_000 # Convert to cornlet
        )

        # Update balances of seed address and new address
        satoshi_address.cornlet_balance = satoshi_address.cornlet_balance - transaction.cornlet_amount
        new_address.cornlet_balance = new_address.cornlet_balance + transaction.cornlet_amount

        if new_address.save && transaction.save && satoshi_address.save
          transactions = Transaction.where(from_address: new_address.address).or(Transaction.where(to_address: new_address.address))

          response_data = {
            balance: new_address.cornlet_balance.to_f / 1_000_000.0,
            transactions: transactions.map do |tx|
              {
                amount: tx.cornlet_amount.to_f / 1_000_000.0,
                timestamp: tx.created_at,
                toAddress: tx.to_address.address,
              }
            end
          }
          render json: response_data, status: :created
        else
          raise ActiveRecord::Rollback, "Failed to create transaction"
        end
      else
        render json: { error: "User: #{new_address.address} already exists, please sign in instead" }, status: :conflict
      end
    end
  rescue ActiveRecord::Rollback
    # If the transaction is rolled back, destroy the new_address record if it was persisted
    new_address.destroy if new_address.persisted?
    render json: { error: 'Failed to create transaction' }, status: :unprocessable_entity
  end

  private

  def record_not_found
    render json: { error: 'Address not found' }, status: :not_found
  end

  def record_invalid(exception)
    render json: { error: "Invalid address: #{exception.message}" }, status: :unprocessable_entity
  end
end
