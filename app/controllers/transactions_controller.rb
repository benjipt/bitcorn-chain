class TransactionsController < ApplicationController
  def create
    transaction_payload = params.require(:transaction).permit(:from_address, :to_address, :amount)
    from_address = Address.find_by(address: transaction_payload[:from_address].downcase) if transaction_payload[:from_address].present?
    to_address = transaction_payload[:to_address].present? ? Address.find_or_create_by(address: transaction_payload[:to_address].downcase) : nil

    if transaction_payload[:amount].nil?
      render json: { error: "Amount is required" }, status: :unprocessable_entity
      return
    end

    if from_address.nil?
      render json: { error: "fromAddress is required" }, status: :unprocessable_entity
      return
    end

    if to_address.nil?
      render json: { error: "toAddress is required" }, status: :unprocessable_entity
      return
    end
    
    # Convert amount to decimal
    amount_decimal = transaction_payload[:amount].to_d

    # Check if amount is valid
    if amount_decimal <= 0
      render json: { error: "Amount should be greater than 0" }, status: :unprocessable_entity
      return
    end
    
    # Check if amount has more than 6 digits to the right of the decimal point
    if amount_decimal.frac.to_s.split('.')[1].size > 6
      render json: { error: "Amount can have no more than 6 digits to the right of the decimal point" }, status: :unprocessable_entity
      return
    end
    
    # Convert unit from bitcorn to cornlet (1 bitcorn == 1_000_000 cornlets)
    amount = (amount_decimal * 1_000_000).to_i

    if from_address.cornlet_balance < amount
      render json: { error: "insufficient balance" }, status: :unprocessable_entity
      return
    end

    transaction = Transaction.new(from_address: from_address, to_address: to_address, cornlet_amount: amount)

    if transaction.save
      from_address.update(cornlet_balance: from_address.cornlet_balance - amount)
      to_address.update(cornlet_balance: to_address.cornlet_balance + amount)
      render json: { status: "success", message: "Transaction created successfully" }, status: :created
    else
      render json: { error: "Unable to create transaction" }, status: :unprocessable_entity
    end
  end
end
