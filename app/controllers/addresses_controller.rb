# frozen_string_literal: true

# addresses_controller.rb
class SeedAddressNotFoundError < StandardError; end

# AddressesController is a controller class that manages the endpoints related
# to the Address model. It provides functionality for showing and creating addresses.
# It handles exceptions related to ActiveRecord and also responds with appropriate
# HTTP status codes and JSON responses for each action.
#
# It includes several private helper methods for fetching transactions associated
# with an address, building response data, initializing an address with a seed transaction,
# creating a new address, saving address and processing transactions, rendering existing
# address error, handling record invalid exception, rendering invalid address, rolling back
# transaction, handling record not found exception and rendering seed address not found error.
#
# The `show` action finds the address using the `find_by!` method which will raise an exception
# if the address is not found. The `create` action creates a new address and a seed transaction
# associated with it. It handles exceptions such as `ActiveRecord::Rollback` and `SeedAddressNotFoundError`.
#
# The create action is responsible for creating a new address and an initial seed transaction.
# It uses the `find_or_initialize_by` method to find an existing address or initialize a new one.
# It also uses the `initialize_seed_transaction` method to initialize a seed transaction.
# It uses the `Address.transaction` method to wrap the creation of an address and a transaction
# in a transaction block. If the transaction fails to save, it will raise an exception which will
# be rescued by the `rescue_from ActiveRecord::RecordInvalid` method and the transaction will be rolled back.
#
# The show action can return the following responses:
#
# - 200 OK: If the address is found.
# - 404 Not Found: If the address is not found.
#
# The create action can return the following responses:
#
# - 201 Created: If the address and transaction are successfully created.
# - 400 Bad Request: If the address is missing from the request body.
# - 422 Unprocessable Entity: If the address is already registered in the system.
# - 500 Internal Server Error: If the seed address is not found in the database.
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
      create_new_address(new_address, transaction)
    else
      render_existing_address_error(new_address)
    end
  rescue ActiveRecord::Rollback
    rollback_transaction(new_address)
  rescue SeedAddressNotFoundError
    render_seed_address_not_found
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
      end,
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

  def create_new_address(new_address, transaction)
    Address.transaction do
      save_address_and_process_transaction(new_address, transaction)
    rescue ActiveRecord::RecordInvalid
      rollback_transaction(new_address)
    end
  end

  def save_address_and_process_transaction(new_address, transaction)
    # Update balances of seed address and new address
    transaction.from_address.cornlet_balance -= transaction.cornlet_amount
    new_address.cornlet_balance += transaction.cornlet_amount

    raise ActiveRecord::Rollback, 'Failed to create transaction' unless new_address.save && transaction.save && transaction.from_address.save

    transactions = find_transactions(new_address)
    response_data = build_response_data(new_address, transactions)
    render json: response_data, status: :created
  end

  def render_existing_address_error(new_address)
    render json: { error: "User: #{new_address.address} already exists, please sign in instead" }, status: :conflict
  end

  def record_invalid(exception)
    render json: { error: "Invalid address: #{exception.message}" }, status: :unprocessable_entity
  end

  def render_invalid_address
    render json: { error: 'Invalid address' }, status: :unprocessable_entity
  end

  def rollback_transaction(new_address)
    # If the transaction is rolled back, destroy the new_address record if it was persisted
    new_address&.destroy if new_address&.persisted?
    render json: { error: 'Failed to create transaction' }, status: :unprocessable_entity
  end

  def record_not_found
    render json: { error: 'Address not found' }, status: :not_found
  end

  def render_seed_address_not_found
    render json: { error: 'Could not find seed address. Unable to create a new user at this time.' }, status: :internal_server_error
  end
end
