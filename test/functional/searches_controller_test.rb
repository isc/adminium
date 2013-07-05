require 'test_helper'

class SearchesControllerTest < ActionController::TestCase

  def setup
    @account = create :account, plan: 'startup'
    session[:account] = @account.id
    FixtureFactory.clear_db
    @fixtures = []
  end

  def test_create_a_search
    put :update, {"filters"=>{"410"=>{"grouping"=>"and", "column"=>"pseudo", "type"=>"string", "operator"=>"null", "operand"=>""}}, "name"=>"last search", "id"=>"users"}
    assert_redirected_to resources_path(:users, asearch: "last search")
    get :show, id: 'users'
    assert_response :success
    assert_equal ['last search'], JSON.parse(response.body)
  end
  
  def test_destroy_a_search
    resource = Resource::Base.new Generic.new(@account), :users
    resource.filters['myass'] = {}
    resource.save
    post :destroy, id: 'users', name: 'myass'
    assert_redirected_to resources_path(:users)
  end

end

