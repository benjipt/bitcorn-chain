# frozen_string_literal: true

namespace :daily_stake_reward do
  desc "Applies daily stake reward to users with cornlet_balance >= 10_000_000"
  task check: :environment do
    DailyStakeRewardJob.perform_now
  end
end
