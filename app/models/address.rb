class Address < ApplicationRecord
  has_many :sent_transactions, class_name: 'Transaction', foreign_key: 'from_address', primary_key: 'address'
  has_many :received_transactions, class_name: 'Transaction', foreign_key: 'to_address', primary_key: 'address'
end
