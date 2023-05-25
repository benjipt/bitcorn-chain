# frozen_string_literal: true

Address.create(
  address: ENV.fetch('SEED_ADDRESS', nil),
  cornlet_balance: 100_000_000_000_000
)
