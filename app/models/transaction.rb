class Transaction < ApplicationRecord
  belongs_to :from_address, class_name: 'Address', foreign_key: 'from_address', primary_key: 'address'
  belongs_to :to_address, class_name: 'Address', foreign_key: 'to_address', primary_key: 'address'

  validates :cornlet_amount, numericality: { less_than_or_equal_to: :sender_balance }

  private

  def sender_balance
    from_address.cornlet_balance
  end
end
