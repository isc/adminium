class Widget < ActiveRecord::Base
  attr_accessible :table, :advanced_search, :order, :type, :columns, :grouping
  validates_presence_of :table
  belongs_to :account
  
  def name
    [advanced_search.presence || 'Listing', table].uniq.join(" on ")
  end
  
  def self.widget_types
    [['Table', 'TableWidget'], ['Time Chart', 'TimeChartWidget'], ['Pie Chart', 'PieChartWidget'], ['Statistics', 'StatChartWidget']]
  end
  
end
