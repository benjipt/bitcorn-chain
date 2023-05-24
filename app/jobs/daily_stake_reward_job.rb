# This is a job class that is responsible for handling daily stake rewards.
# The stake rewards are transferred from the seed address ('satoshi kozuka') to each
# address that has a cornlet_balance greater than or equal to 10,000,000 Cornlets.
# This job is processed in the default queue.
class DailyStakeRewardJob < ApplicationJob
  # Uses the default queue for this job.
  queue_as :default

  # Executes the job. It finds the seed address and verifies if it has enough balance.
  # If the balance is sufficient, it proceeds to transfer stake rewards to qualified addresses.
  # Qualified addresses are those having a cornlet_balance >= 10_000_000 and not equal to the seed address.
  def perform
    seed_address = Address.find_by(address: 'satoshi kozuka')
    unless seed_address && seed_address.cornlet_balance >= 25_000_000
      Rails.logger.info "Satoshi Kozuka's address does not exist or doesn't have enough balance."
      return
    end

    # For each address with cornlet_balance >= 10_000_000 except Satoshi, generate a stake reward transaction.
    Address.where('cornlet_balance >= ? AND address <> ?', 10_000_000, 'satoshi kozuka').find_each do |address|
      process_address(address, seed_address)
    end
  end

  private

  # Processes each qualified address by creating a transaction and updating balances.
  # It does this within a database transaction to ensure consistency.
  # If a record fails to save, it logs the error and does not halt the execution of the job.
  def process_address(address, seed_address)
    ActiveRecord::Base.transaction do
      create_transaction(address, seed_address)
      update_balances(address, seed_address)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.info "Failed to save transaction for #{address.address}. Errors: #{e}"
    end
  end

  # Creates a transaction from the seed address to the provided address.
  # The transaction amount is fixed at 25,000,000 Cornlets.
  # It saves the transaction with a bang method to raise an exception on failure.
  def create_transaction(address, seed_address)
    transaction = Transaction.new(
      from_address: seed_address,
      to_address: address,
      cornlet_amount: 25_000_000
    )

    transaction.save!
  end

  # Updates the balances of the seed address and the recipient address.
  # The recipient's balance is increased, and the seed address's balance is decreased by 25,000,000 Cornlets.
  # Both changes are saved with a bang method to raise an exception on failure.
  def update_balances(address, seed_address)
    address.cornlet_balance += 25_000_000
    address.save!

    seed_address.cornlet_balance -= 25_000_000
    seed_address.save!
  end
end
