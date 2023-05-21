class DailyStakeRewardJob < ApplicationJob
  queue_as :default

  def perform
    satoshi = Address.find_by(address: 'satoshi kozuka')
    unless satoshi && satoshi.cornlet_balance >= 25_000_000
      Rails.logger.info "Satoshi Kozuka's address does not exist or doesn't have enough balance."
      return
    end

    # For each address with cornlet_balance >= 10_000_000 except Satoshi, generate a stake reward transaction.
    Address.where('cornlet_balance >= ? AND address <> ?', 10_000_000, 'satoshi kozuka').find_each do |address|
      process_address(address, satoshi)
    end
  end

  private

  def process_address(address, satoshi)
    ActiveRecord::Base.transaction do
      create_transaction(address, satoshi)
      update_balances(address, satoshi)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.info "Failed to save transaction for #{address.address}. Errors: #{e}"
    end
  end

  def create_transaction(address, satoshi)
    transaction = Transaction.new(
      from_address: satoshi,
      to_address: address,
      cornlet_amount: 25_000_000
    )

    transaction.save!
  end

  def update_balances(address, satoshi)
    address.cornlet_balance += 25_000_000
    address.save!

    satoshi.cornlet_balance -= 25_000_000
    satoshi.save!
  end
end
