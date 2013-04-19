require 'test_helper'

class SearchesControllerTest < ActionController::TestCase

  def setup
    @account = Factory :account, plan: 'startup'
    session[:account] = @account.id
    FixtureFactory.clear_db
    @fixtures = []
  end

  def test_create_a_search
    put :update, {"filters"=>{"410"=>{"grouping"=>"and", "column"=>"pseudo", "type"=>"string", "operator"=>"null", "operand"=>""}}, "name"=>"last search", "id"=>"users"}
    assert_redirected_to resources_path(:users, asearch: "last search")
  end
  
  def test_destroy_a_search
    resource = Resource::Base.new Generic.new(@account), :users
    resource.filters['myass'] = {}
    resource.save
    post :destroy, id: 'users', name: 'myass'
    assert_redirected_to resources_path(:users)
  end
  
  def test_partials
    [:id, :created_at, :pseudo].each do |column|
      get :show, id: 'users', column_name: column
      assert_response :success
    end
  end


end

