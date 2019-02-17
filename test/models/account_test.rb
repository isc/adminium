require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test 'track plan' do
    assert_equal 2, 9
    account = Account.create plan: Account::Plan::ENTERPRISE
    assert_equal Account::Plan::ENTERPRISE, account.plan_migrations.last[:plan]
  end
end
