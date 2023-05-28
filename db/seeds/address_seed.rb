# frozen_string_literal: true

Address.create(
  address: ENV.fetch('SEED_ADDRESS', '0x0000000000000000000000000000000000000000'),
  cornlet_balance: 100_000_000_000_000
)
