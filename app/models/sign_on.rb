class SignOn < ActiveRecord::Base
  attr_accessible :account_id, :plan, :remote_ip, :kind, :user_id
  class Kind
    HEROKU = 0
    GOOGLE = 1
    HEROKU_OAUTH = 2
  end
  
end
