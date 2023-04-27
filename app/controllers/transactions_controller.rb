class TransactionsController < ApplicationController
  def create
    transaction_payload = params.require(:transaction).permit(:from_address, :to_address, :amount)
    from_address = Address.find_by(address: transaction_payload[:from_address])
    to_address = transaction_payload[:to_address].present? ? Address.find_or_create_by(address: transaction_payload[:to_address]) : nil
    amount = transaction_payload[:amount].to_i

    if from_address.nil?
      render json: { error: "From address not found" }, status: :unprocessable_entity
      return
    end

    if to_address.nil?
      render json: { error: "To address is required" }, status: :unprocessable_entity
      return
    end

    if from_address.cornlet_balance < amount
      render json: { error: "insufficient cornlet_balance" }, status: :unprocessable_entity
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
