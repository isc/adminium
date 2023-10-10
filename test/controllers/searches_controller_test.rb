require 'test_helper'

class SearchesControllerTest < ActionController::TestCase
  def setup
    @account = create_account_and_login
    @fixtures = []
  end

  def test_show_searches
    create :search, name: 'my search', table: 'users', account: @account, generic: Generic.new(@account)
    get :show, params: { id: 'users' }
    assert_response :success
    assert_equal ['my search'], JSON.parse(response.body)
  end
end
