class Widget < ActiveRecord::Base
  attr_accessible :table, :advanced_search, :order, :type, :columns, :grouping
  validates_presence_of :table
  belongs_to :account
  
  def name
    [advanced_search.presence, table].uniq.join(" on ")
  end
  
end
