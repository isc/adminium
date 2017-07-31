require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  def test_auto_provision_the_addon
    db_url = 'postgres://u:p@h/d'
    addon = stub(create: nil, list: [{'app' => {'name' => 'test-addon'}, 'id' => 37}])
    config_var = stub(info: {'DATABASE_URL' => db_url})
    app = stub(info: {'owner' => {'email' => 'ma@il.com'}})
    collaborator = stub(list: [])
    AccountsController.any_instance.stubs(:heroku_api)
                      .returns stub(addon: addon, config_var: config_var, app: app, collaborator: collaborator)
    # Should be done by heroku during the create request
    account = create :account, heroku_uuid: '37', db_url: nil
    post :create, params: {name: 'test-addon', app_id: 37, plan: 'petproject'}
    assert_response :success
    assert_equal({'success' => true, 'redirect_path' => '/dashboard'}, JSON.parse(@response.body))
    assert_equal account.id, session[:account]
    assert_equal 'test-addon', account.reload.name
    assert_equal db_url, account.db_url
    assert_equal 'ma@il.com', account.owner_email
    assert_equal 'self-create', account.db_url_setup_method
  end
end
