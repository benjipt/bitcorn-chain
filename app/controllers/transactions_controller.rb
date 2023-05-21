class TransactionsController < ApplicationController
  before_action :load_params, only: :create

  def create
    return unless valid_transaction?

    create_transaction
  end

  private

  def load_params
    @transaction_payload = params.require(:transaction).permit(:from_address, :to_address, :amount)
    @from_address = find_address(@transaction_payload[:from_address])
    @to_address = find_or_create_address(@transaction_payload[:to_address])
    # 1_000_000 is used to convert the amount to the smallest unit of Bitcorn (1 Bitcorn = 1_000_000 Cornlets)
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
      to_address_required: 'toAddress is required'
    }
    return error_response(errors[:amount_required]) if @amount.nil?
    return error_response(errors[:from_address_required]) if @from_address.nil?
    return error_response(errors[:to_address_required]) if @to_address.nil?

    true
  end

  def check_amount
    errors = {
      invalid_amount: 'Amount should be greater than 0',
      invalid_decimal_digits: 'Amount can have no more than 6 digits to the right of the decimal point'
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

  def create_transaction
    transaction = Transaction.new(from_address: @from_address, to_address: @to_address, cornlet_amount: @amount)

    if transaction.save
      update_balances
      render json: { status: "success", message: "Transaction created successfully" }, status: :created
    else
      error_response("Unable to create transaction")
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

  def error_response(message)
    render json: { error: message }, status: :unprocessable_entity
    false
  end

  def update_balances
    @from_address.update(cornlet_balance: @from_address.cornlet_balance - @amount)
    @to_address.update(cornlet_balance: @to_address.cornlet_balance + @amount)
  end
end
