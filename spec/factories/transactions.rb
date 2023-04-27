# spec/factories/transactions.rb
FactoryBot.define do
  factory :transaction do
    from_address { "test_from_address" }
    to_address { "test_to_address" }
    cornlet_amount { 50 }
  end
end
