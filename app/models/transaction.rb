# frozen_string_literal: true

# Transaction
#
# The Transaction class represents a record of transfer of Bitcorns (in its smallest unit, Cornlets)
# between two addresses in the system. It inherits from ApplicationRecord, thus enjoying the benefits
# of the Rails model layer including lifecycle callbacks, validation and transaction control, among
# other features.
#
# Relationships:
# - belongs_to :from_address: This represents the sender's address. The foreign key in the transactions
# table is 'from_address' and it maps to the 'address' field in the 'addresses' table.
# - belongs_to :to_address: This represents the receiver's address. The foreign key in the transactions
# table is 'to_address' and it maps to the 'address' field in the 'addresses' table.
#
# Validations:
# - cornlet_amount: Ensures that the amount to be transferred is less than or equal to the balance of
# the sender's address.
#
# Class Methods:
# - create_and_process: This method handles the transaction creation and processing. It accepts three
# parameters, the sender's address, receiver's address, and the amount to be transferred. It first attempts
# to create a new transaction with the provided details. If successful, it deducts the amount from the sender's
# balance and adds it to the receiver's balance, and returns true. If unsuccessful, it simply returns false.
#
# Private Instance Methods:
# - sender_balance: This method fetches the balance of the sender's address.
class Transaction < ApplicationRecord
  belongs_to :from_address, class_name: 'Address', foreign_key: 'from_address', primary_key: 'address', inverse_of: :sent_transactions
  belongs_to :to_address, class_name: 'Address', foreign_key: 'to_address', primary_key: 'address', inverse_of: :received_transactions

  validates :cornlet_amount, numericality: { less_than_or_equal_to: :sender_balance }

  # Method to create transaction, update balances and save changes to the database
  def self.create_and_process(from_address, to_address, amount)
    transaction = Transaction.new(from_address:, to_address:, cornlet_amount: amount)

    if transaction.save
      from_address.update(cornlet_balance: from_address.cornlet_balance - amount)
      to_address.update(cornlet_balance: to_address.cornlet_balance + amount)
      true
    else
      false
    end
  end

  private

  def sender_balance
    from_address.cornlet_balance
  end
end
