require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test 'track plan' do
    account = Account.create plan: Account::Plan::ENTERPRISE
    assert_equal Account::Plan::ENTERPRISE, account.plan_migrations.last[:plan]
  end
end
