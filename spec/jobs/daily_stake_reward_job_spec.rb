# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DailyStakeRewardJob, type: :job do
  describe '#perform' do
    let!(:satoshi) { create(:address, address: 'satoshi kozuka', cornlet_balance: 100_000_000_000) }
    let!(:address1) { create(:address, cornlet_balance: 10_000_000) }
    let!(:address2) { create(:address, cornlet_balance: 9_999_999) }
    let!(:address3) { create(:address, cornlet_balance: 15_000_000) }

    context 'when Satoshi has enough balance' do
      it 'creates transactions and updates balances' do
        expect { DailyStakeRewardJob.perform_now }
          .to change { Transaction.count }.by(2)
          .and change { address1.reload.cornlet_balance }.by(25_000_000)
          .and change { address3.reload.cornlet_balance }.by(25_000_000)
          .and change { satoshi.reload.cornlet_balance }.by(-50_000_000)

        transaction1 = Transaction.find_by(from_address: satoshi.address, to_address: address1.address)
        expect(transaction1.cornlet_amount).to eq(25_000_000)

        transaction3 = Transaction.find_by(from_address: satoshi.address, to_address: address3.address)
        expect(transaction3.cornlet_amount).to eq(25_000_000)
      end

      it 'does not process addresses with balance less than 10_000_000' do
        expect { DailyStakeRewardJob.perform_now }.not_to(change { address2.reload.cornlet_balance })
      end
    end

    context 'when Satoshi does not have enough balance' do
      before do
        satoshi.update!(cornlet_balance: 1)
      end

      it 'does not create any transactions' do
        expect { DailyStakeRewardJob.perform_now }
          .not_to(change { Transaction.count })
      end

      it 'does not update any balances' do
        expect { DailyStakeRewardJob.perform_now }.not_to(change { Transaction.count })
        expect { DailyStakeRewardJob.perform_now }.not_to(change { satoshi.reload.cornlet_balance })
        expect { DailyStakeRewardJob.perform_now }.not_to(change { address1.reload.cornlet_balance })
        expect { DailyStakeRewardJob.perform_now }.not_to(change { address3.reload.cornlet_balance })
      end
    end
  end
end
