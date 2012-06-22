class Widget < ActiveRecord::Base
  attr_accessible :table, :advanced_search, :order
  validates_presence_of :table
end
