# frozen_string_literal: true

# spec/factories/addresses.rb
FactoryBot.define do
  factory :address do
    sequence(:address) { |n| "test_address_#{n}" }
    cornlet_balance { 100 }
  end
end
