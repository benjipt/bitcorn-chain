# addresses_controller.rb
class SeedAddressNotFoundError < StandardError; end

class AddressesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def show
    address = Address.find_by!(address: params[:id].downcase)
    transactions = find_transactions(address)
    response_data = build_response_data(address, transactions)
    render json: response_data
  end

  def create
    return render_invalid_address if params[:address].blank?

    new_address, transaction = initialize_address_with_seed_transaction

    if new_address.new_record?
      Address.transaction do
        save_address_and_process_transaction(new_address, transaction)
      rescue ActiveRecord::RecordInvalid
        handle_transaction_rollback(new_address)
      end
    else
      render json: { error: "User: #{new_address.address} already exists, please sign in instead" }, status: :conflict
    end
  rescue ActiveRecord::Rollback
    # If the transaction is rolled back, destroy the new_address record if it was persisted
    new_address&.destroy if new_address&.persisted?
    render json: { error: 'Failed to create transaction' }, status: :unprocessable_entity
  rescue SeedAddressNotFoundError
    render json: { error: 'Could not find seed address. Unable to create a new user at this time.' }, status: :internal_server_error
  end

  private

  def find_transactions(address)
    Transaction.where(from_address: address.address).or(Transaction.where(to_address: address.address))
  end

  def build_response_data(address, transactions)
    {
      balance: address.cornlet_balance.to_f / 1_000_000.0,
      transactions: transactions.map do |transaction|
        {
          amount: transaction.cornlet_amount.to_f / 1_000_000.0,
          timestamp: transaction.created_at,
          toAddress: transaction.to_address.address,
        }
      end
    }
  end

  def initialize_address_with_seed_transaction
    new_address = Address.find_or_initialize_by(address: params[:address].downcase)
    satoshi_address = Address.find_by(address: 'satoshi kozuka') || raise(SeedAddressNotFoundError)
    transaction = initialize_seed_transaction(satoshi_address, new_address) if new_address.new_record?
    [new_address, transaction]
  end

  def initialize_seed_transaction(satoshi_address, new_address)
    Transaction.new(
      from_address: satoshi_address,
      to_address: new_address,
      cornlet_amount: 100 * 1_000_000 # Convert to cornlet
    )
  end

  def save_address_and_process_transaction(new_address, transaction)
    # Update balances of seed address and new address
    transaction.from_address.cornlet_balance -= transaction.cornlet_amount
    new_address.cornlet_balance += transaction.cornlet_amount

    if new_address.save && transaction.save && transaction.from_address.save
      transactions = find_transactions(new_address)
      response_data = build_response_data(new_address, transactions)
      render json: response_data, status: :created
    else
      raise ActiveRecord::Rollback, "Failed to create transaction"
    end
  end

  def render_invalid_address
    render json: { error: 'Invalid address' }, status: :unprocessable_entity
  end

  def handle_transaction_rollback(new_address)
    new_address&.destroy if new_address&.persisted?
    render json: { error: 'Failed to create transaction' }, status: :unprocessable_entity
  end

  def record_not_found
    render json: { error: 'Address not found' }, status: :not_found
  end

  def record_invalid(exception)
    render json: { error: "Invalid address: #{exception.message}" }, status: :unprocessable_entity
  end
end
