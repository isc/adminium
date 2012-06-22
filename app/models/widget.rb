class Widget < ActiveRecord::Base
  attr_accessible :table, :advanced_search, :order
  validates_presence_of :table
  belongs_to :account
end
