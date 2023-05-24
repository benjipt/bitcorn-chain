# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Address, type: :model do
  describe 'associations' do
    it { should have_many(:sent_transactions).class_name('Transaction').with_foreign_key('from_address').with_primary_key('address') }
    it { should have_many(:received_transactions).class_name('Transaction').with_foreign_key('to_address').with_primary_key('address') }
  end
end
