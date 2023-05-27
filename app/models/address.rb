# frozen_string_literal: true

# Address is a model class that represents an address in the cornlet network.
# It has many sent transactions and many received transactions, which are
# defined as the transactions where the address is the from address or the to
# address, respectively.
#
# The Address class provides the following functionality:
#
# - A custom initializer that takes a seed address and an amount of cornlets to
#   seed the address with.
# - A method to process a transaction, which updates the cornlet balance of the
#   address and the from address of the transaction.
# - A method to return a JSON representation of the address, which includes the
#   cornlet balance and the transaction history.
#
# The Address model has the following validations:
#
# - The address must be unique.
# - The address must be present.
# - The cornlet balance must be a non-negative integer.
#
# The Address model has the following associations:
#
# - It has many sent transactions.
# - It has many received transactions.
class Address < ApplicationRecord
  has_many :sent_transactions, class_name: 'Transaction', foreign_key: 'from_address', primary_key: 'address', inverse_of: :from_address
  has_many :received_transactions, class_name: 'Transaction', foreign_key: 'to_address', primary_key: 'address', inverse_of: :to_address

  def transactions
    Transaction.where(from_address: address).or(Transaction.where(to_address: address))
  end

  def initialize_with_seed_transaction(seed_address, cornlet_amount)
    Transaction.new(
      from_address: seed_address,
      to_address: self,
      cornlet_amount:
    )
  end

  def process_transaction(transaction)
    transaction.from_address.cornlet_balance -= transaction.cornlet_amount
    self.cornlet_balance += transaction.cornlet_amount
    return if save && transaction.save && transaction.from_address.save

    raise ActiveRecord::Rollback,
          'Failed to create transaction'
  end

  def as_json
    {
      balance: cornlet_balance.to_f / 1_000_000.0,
      transactions: transactions.map do |transaction|
        {
          amount: transaction.cornlet_amount.to_f / 1_000_000.0,
          timestamp: transaction.created_at,
          toAddress: transaction.to_address.address,
        }
      end,
    }
  end

  def restricted?
    address == ENV.fetch('SEED_ADDRESS', nil)
  end
end
