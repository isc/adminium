require 'test_helper'

class SettingsControllerTest < ActionController::TestCase

  def setup
    @account = create :account, plan: 'startup'
    session[:account] = @account.id
    FixtureFactory.clear_db
    @fixtures = []
  end

  test "enum" do
    FixtureFactory.new :user, pseudo: 'bob'
    FixtureFactory.new :user, pseudo: 'bob'
    FixtureFactory.new :user, pseudo: 'michel'
    get :values, id: 'users', column_name: 'pseudo'
    assert_equal ["bob", "michel"], JSON.parse(@response.body)
  end
  
  test "partials" do
    [:id, :created_at, :pseudo].each do |column|
      get :show, id: 'users', column_name: column
      assert_response :success
    end
  end
  
  test "columns" do
    user = FixtureFactory.new(:user).factory
    get :columns, table: 'users'
    assert_equal user.attributes.keys.sort, JSON.parse(@response.body)
  end

end
