class Widget < ActiveRecord::Base
  attr_accessible :table, :account_id, :advanced_search
  validates_presence_of :table
end
