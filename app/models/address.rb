# models/address.rb
#
# The Address model represents addresses within the application.
# Each address can be associated with multiple transactions, both as a sender (from_address) and as a receiver (to_address).
#
# == Schema Information
#
# Table name: addresses
#
# Columns:
# * id (integer)
# * address (string)
# * cornlet_balance (integer)
# * created_at (datetime)
# * updated_at (datetime)
#
# Each Address has two associations with the Transaction model:
# * sent_transactions: A one-to-many relationship where the foreign key on the Transaction is from_address and
# the primary key on the Address is address.
# * received_transactions: A one-to-many relationship where the foreign key on the Transaction is to_address and
# the primary key on the Address is address.
#
# The inverse_of option is set on each of these associations, allowing Rails to know that the two associations are inverses of each other.
# This means that if you have the object on one side of the association, you can get the object on the other side
# without going through the database.
class Address < ApplicationRecord
  has_many :sent_transactions, class_name: 'Transaction', foreign_key: 'from_address', primary_key: 'address', inverse_of: :from_address
  has_many :received_transactions, class_name: 'Transaction', foreign_key: 'to_address', primary_key: 'address', inverse_of: :to_address
end
