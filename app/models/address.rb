# models/address.rb
class Address < ApplicationRecord
  has_many :sent_transactions, class_name: 'Transaction', foreign_key: 'from_address', primary_key: 'address', inverse_of: :from_address
  has_many :received_transactions, class_name: 'Transaction', foreign_key: 'to_address', primary_key: 'address', inverse_of: :to_address
end
