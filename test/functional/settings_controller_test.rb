require 'test_helper'

class SettingsControllerTest < ActionController::TestCase

  def setup
    @account = Factory :account, plan: 'startup'
    session[:account] = @account.id
    FixtureFactory.clear_db
    @fixtures = []
  end

  def test_enum
    FixtureFactory.new :user, pseudo: 'bob'
    FixtureFactory.new :user, pseudo: 'bob'
    FixtureFactory.new :user, pseudo: 'michel'
    get :values, id: 'users', column_name: 'pseudo'
    assert_equal ["bob", "michel"], JSON.parse(@response.body)
  end


end