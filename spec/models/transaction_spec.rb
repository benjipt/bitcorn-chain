require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'associations' do
    it { should belong_to(:from_address).class_name('Address').with_foreign_key('from_address').with_primary_key('address') }
    it { should belong_to(:to_address).class_name('Address').with_foreign_key('to_address').with_primary_key('address') }
  end
end
