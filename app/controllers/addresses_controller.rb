# frozen_string_literal: true

class SeedAddressNotFoundError < StandardError; end

# AddressesController is a controller class that manages the endpoints related
# to the Address model. It provides functionality for showing and creating addresses.
#
# The show action returns the balance and transaction history for a given address.
# The create action creates a new address and an initial transaction to seed the
# address with cornlets, then returns the balance and transaction history for the
# new address.
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
    render json: address.as_json
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

  def initialize_address_with_seed_transaction
    new_address = Address.find_or_initialize_by(address: params[:address].downcase)
    seed_address = Address.find_by(address: 'satoshi kozuka') || raise(SeedAddressNotFoundError)
    transaction = new_address.initialize_with_seed_transaction(seed_address, 100 * 1_000_000) if new_address.new_record?
    [new_address, transaction]
  end

  def create_new_address(new_address, transaction)
    Address.transaction do
      new_address.process_transaction(transaction)
    end
    render json: new_address.as_json, status: :created
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
