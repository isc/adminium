class Widget < ActiveRecord::Base
  attr_accessible :table, :advanced_search, :order, :type, :columns, :grouping
  validates_presence_of :table
  belongs_to :account
end
