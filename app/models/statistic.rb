class Statistic < ActiveRecord::Base
  validates :action, uniqueness: {scope: :account_id}
  validates :action, :account_id, presence: true
end
