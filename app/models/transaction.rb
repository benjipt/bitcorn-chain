class Transaction < ApplicationRecord
  belongs_to :from_address, class_name: 'Address', foreign_key: 'from_address', primary_key: 'address'
  belongs_to :to_address, class_name: 'Address', foreign_key: 'to_address', primary_key: 'address'
end
