class SignOn < ActiveRecord::Base
  class Kind
    HEROKU = 0
    GOOGLE = 1
    HEROKU_OAUTH = 2
  end
end
