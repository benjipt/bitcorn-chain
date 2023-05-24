# frozen_string_literal: true

every 1.day, at: '00:01 am' do
  runner 'DailyStakeRewardJob.perform_later'
end
