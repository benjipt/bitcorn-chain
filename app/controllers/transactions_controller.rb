# frozen_string_literal: true

# TransactionsController
#
# The TransactionsController is responsible for handling HTTP requests related to transactions in the
# application. A transaction represents a transfer of Bitcorn
# (represented in its smallest unit, Cornlets) between two addresses. The controller contains actions
# to create new transactions.
#
# Actions:
# - create: creates a new transaction
#
# The create action is as follows:
# - First, it loads transaction parameters (from_address, to_address, amount) from the HTTP request
# - Then it checks the validity of the transaction by ensuring all required fields are present, the amount
# is greater than 0 and not too precise, and the sender has enough balance.
# - If the transaction is valid, it calls a method in the Transaction model that encapsulates transaction
# creation and balance updating.
# - If the transaction is created successfully, it renders a JSON response with a success message and a HTTP
# status code of 201.
# - If the transaction is not created successfully, it renders a JSON error message with a HTTP status
# code of 422.
#
# The controller uses several private helper methods to validate transactions and handle errors. These include
# methods to check the presence of required fields, validate the transaction amount, check the sender's balance,
# and return an error response if needed.
#
# All addresses are normalized to lowercase for consistency.
#
# The 'load_params' method is run before the create action. This method loads and validates the parameters of
# the transaction from the request body.
#
# The 'find_address' and 'find_or_create_address' methods return an address from the database based on the given
# address, if present.
# 'find_or_create_address' will create a new address if the given address is not found.
#
# The 'check_balance' method checks if the sender has a sufficient balance to carry out the transaction.
#
# The 'error_response' method is used to render a JSON error message with a status of 422 (unprocessable entity).
#
# The 'decimal_size' method returns the size of the decimal portion of a decimal number.
class TransactionsController < ApplicationController
  before_action :load_params, only: :create

  def create
    return unless valid_transaction?

    if Transaction.create_and_process(@from_address, @to_address, @amount)
      render json: { status: 'success', message: 'Transaction created successfully' }, status: :created
    else
      error_response('Unable to create transaction')
    end
  end

  private

  def load_params
    @transaction_payload = params.require(:transaction).permit(:from_address, :to_address, :amount)
    @from_address = find_address(@transaction_payload[:from_address])
    @to_address = find_or_create_address(@transaction_payload[:to_address])
    @amount = (@transaction_payload[:amount].to_d * 1_000_000).to_i if @transaction_payload[:amount]
  end

  def find_address(address)
    Address.find_by(address: address.downcase) if address.present?
  end

  def find_or_create_address(address)
    address.present? ? Address.find_or_create_by(address: address.downcase) : nil
  end

  def valid_transaction?
    check_required_fields && check_amount && check_balance
  end

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

  def check_amount
    errors = {
      invalid_amount: 'Amount should be greater than 0',
      invalid_decimal_digits: 'Amount can have no more than 6 digits to the right of the decimal point',
    }
    return error_response(errors[:invalid_amount]) if @amount <= 0
    return error_response(errors[:invalid_decimal_digits]) if decimal_size(@transaction_payload[:amount].to_d) > 6

    true
  end

  def check_balance
    error = 'insufficient balance'
    return error_response(error) if @from_address.cornlet_balance < @amount

    true
  end

  def decimal_size(decimal)
    decimal.frac.to_s.split('.')[1].size
  end

  def error_response(message)
    render json: { error: message }, status: :unprocessable_entity
    false
  end
end
