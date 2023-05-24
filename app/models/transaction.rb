# models/transaction.rb
#
# The Transaction model represents transactions within the application.
# Each transaction belongs to both a sender and receiver represented by the 'from_address' and 'to_address' fields respectively.
#
# == Schema Information
#
# Table name: transactions
#
# Columns:
# * id (integer)
# * from_address (string)
# * to_address (string)
# * cornlet_amount (integer)
# * created_at (datetime)
# * updated_at (datetime)
#
# Each Transaction has two associations with the Address model:
# * from_address: A belongs_to relationship where the foreign key on the Transaction is from_address
# and the primary key on the Address is address.
# * to_address: A belongs_to relationship where the foreign key on the Transaction is to_address
# and the primary key on the Address is address.
#
# The inverse_of option is set on each of these associations, allowing Rails to know that the two associations are inverses of each other.
# This means that if you have the object on one side of the association, you can get the object on the other side without
# going through the database.
#
# The model also includes a validation for the cornlet_amount to ensure it does not exceed the balance of the sender's address.
class Transaction < ApplicationRecord
  belongs_to :from_address, class_name: 'Address', foreign_key: 'from_address', primary_key: 'address', inverse_of: :sent_transactions
  belongs_to :to_address, class_name: 'Address', foreign_key: 'to_address', primary_key: 'address', inverse_of: :received_transactions

  validates :cornlet_amount, numericality: { less_than_or_equal_to: :sender_balance }

  private

  def sender_balance
    from_address.cornlet_balance
  end
end
