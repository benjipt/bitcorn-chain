# frozen_string_literal: true

# This controller manages transactions within the application.
# Transactions have the fields 'from_address', 'to_address' and 'amount'.
# Each transaction transfers an amount from a sender to a receiver, denoted by their respective addresses.
# The amounts are in the smallest unit of Bitcorn, the Cornlet (1 Bitcorn = 1_000_000 Cornlets).
# The controller checks for validation before processing a transaction such as required fields, sufficient balance and amount validity.

# The create action can return the following responses:
#
# - 201 Created: If the transaction is successfully created.
# - 422 Unprocessable Entity: If the transaction is invalid.
class TransactionsController < ApplicationController
  # Loads the transaction parameters before running the create action.
  before_action :load_params, only: :create

  # Creates a new transaction if the transaction is valid.
  def create
    return unless valid_transaction?

    create_transaction
  end

  private

  # Loads and validates the parameters of the transaction from the request body.
  def load_params
    @transaction_payload = params.require(:transaction).permit(:from_address, :to_address, :amount)
    @from_address = find_address(@transaction_payload[:from_address])
    @to_address = find_or_create_address(@transaction_payload[:to_address])
    # 1_000_000 is used to convert the amount to the smallest unit of Bitcorn (1 Bitcorn = 1_000_000 Cornlets)
    @amount = (@transaction_payload[:amount].to_d * 1_000_000).to_i if @transaction_payload[:amount]
  end

  # Returns an address from the database based on the given address, if present.
  def find_address(address)
    Address.find_by(address: address.downcase) if address.present?
  end

  # Finds or creates an address in the database based on the given address, if present.
  def find_or_create_address(address)
    address.present? ? Address.find_or_create_by(address: address.downcase) : nil
  end

  # Checks if the transaction has all required fields, a valid amount and a sufficient balance.
  def valid_transaction?
    check_required_fields && check_amount && check_balance
  end

  # Checks if the transaction has all the required fields and returns error messages if they are missing.
  def check_required_fields
    errors = {
      amount_required: 'Amount is required',
      from_address_required: 'fromAddress is required',
      to_address_required: 'toAddress is required',
    }
    return error_response(errors[:amount_required]) if @amount.nil?
    return error_response(errors[:from_address_required]) if @from_address.nil?
    return error_response(errors[:to_address_required]) if @to_address.nil?

    true
  end

  # Checks if the transaction amount is greater than 0 and has no more than 6 digits to the right of the decimal point.
  def check_amount
    errors = {
      invalid_amount: 'Amount should be greater than 0',
      invalid_decimal_digits: 'Amount can have no more than 6 digits to the right of the decimal point',
    }
    return error_response(errors[:invalid_amount]) if @amount <= 0
    return error_response(errors[:invalid_decimal_digits]) if decimal_size(@transaction_payload[:amount].to_d) > 6

    true
  end

  # Checks if the sender has a sufficient balance to carry out the transaction.
  def check_balance
    error = 'insufficient balance'
    return error_response(error) if @from_address.cornlet_balance < @amount

    true
  end

  # Creates a new transaction with the loaded parameters and saves it to the database. Updates the balance on successful transaction.
  def create_transaction
    transaction = Transaction.new(from_address: @from_address, to_address: @to_address, cornlet_amount: @amount)

    if transaction.save
      update_balances
      render json: { status: 'success', message: 'Transaction created successfully' }, status: :created
    else
      error_response('Unable to create transaction')
    end
  end

  # Because Bitcorn is divisible to 6 decimal places.
  # Determines the size of the decimal portion of a number.
  # @param decimal [Decimal] The decimal number to check.
  # @return [Integer] The size of the decimal portion.
  def decimal_size(decimal)
    # convert the fractional part of the decimal to a string,
    # split at the decimal point, and return the size of the fraction part
    decimal.frac.to_s.split('.')[1].size
  end

  # Renders a json error message with a status of 422 (unprocessable entity).
  def error_response(message)
    render json: { error: message }, status: :unprocessable_entity
    false
  end

  # Updates the balance of the sender and receiver after a successful transaction.
  def update_balances
    @from_address.update(cornlet_balance: @from_address.cornlet_balance - @amount)
    @to_address.update(cornlet_balance: @to_address.cornlet_balance + @amount)
  end
end
