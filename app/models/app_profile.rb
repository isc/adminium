class AppProfile < ActiveRecord::Base
  attr_accessible :account_id, :app_infos, :addons_infos
end
