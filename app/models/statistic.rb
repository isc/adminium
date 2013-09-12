class Statistic < ActiveRecord::Base
  
  attr_accessible :action, :account_id, :value
  
  validates_uniqueness_of :action, scope: :account_id
  validates_presence_of :action, :account_id
  
end
