class Widget < ActiveRecord::Base
  validates :table, presence: true
  belongs_to :account

  def name
    [advanced_search.presence || 'Listing', table].uniq.join(' on ')
  end

  def self.widget_types
    [['Table', 'TableWidget'], ['Time Chart', 'TimeChartWidget'], ['Pie Chart', 'PieChartWidget'], ['Statistics', 'StatChartWidget']]
  end
end
