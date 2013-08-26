require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  
  def test_auto_provision_the_addon
    session[:heroku_access_token] = '123'
    db_url = "postgres://mm:4vb9@ec2-54-225-96-191.compute-1.amazonaws.com:5432/d3c"
    heroku_api = Heroku::API.new(api_key: '123', mock: true)
    data = heroku_api.post_app(name: 'test-addon').data[:body]
    heroku_api.put_config_vars('test-addon', "DATABASE_URL" => db_url)
    account = Factory :account, heroku_id: "app#{data['id']}@heroku.com", db_url: nil # should be done by heroku during the create request
    post :create, name: 'test-addon', app_id: data['id'], plan: 'petproject'
    assert_response :success
    assert_equal({'success' => true}, JSON.parse(@response.body))
    heroku_api.delete_app 'test-addon'
    assert_equal session[:account], account.id
    assert_equal 'test-addon', account.reload.name
    assert_equal db_url, account.db_url
    assert_equal 'self-create', account.db_url_setup_method
  end
  
end