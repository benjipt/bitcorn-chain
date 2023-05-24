# frozen_string_literal: true

# spec/factories/transactions.rb
FactoryBot.define do
  factory :transaction do
    association :from_address, factory: :address
    association :to_address, factory: :address
    cornlet_amount { 50 }
  end
end
