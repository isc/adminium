require 'test_helper'

class Heroku::ResourcesControllerTest < ActionController::TestCase
  def test_create_account_from_heroku_sso
    assert_difference 'Account.count' do
      create_account 'app138@heroku.com'
    end
  end

  def test_update_deleted_account
    id = 'app37@heroku.com'
    account = create :account, heroku_id: id, plan: 'deleted', deleted_at: 3.days.ago
    assert_no_difference 'Account.count' do
      create_account(id)
    end
    assert_equal account.reload.api_key, JSON.parse(@response.body)['id']
    account = Account.where(heroku_id: id).last
    assert_equal %w(deleted startup), account.plan_migrations.map {|d| d[:plan]}
    assert_nil account.deleted_at
  end

  private

  def create_account id
    @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(HEROKU_MANIFEST['id'], HEROKU_MANIFEST['api']['password'])
    post :create, resource: {heroku_id: id, plan: 'startup', callback_url: 'blablal', bad_key: 'lol'}
    assert_response :success
  end
end
