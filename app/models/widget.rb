class Widget < ApplicationRecord
  validates :table, presence: true
  belongs_to :account

  def name
    [advanced_search.presence || 'Listing', table].uniq.join(' on ')
  end

  def self.widget_types
    [%w[Table TableWidget], ['Time Chart', 'TimeChartWidget'], ['Pie Chart', 'PieChartWidget'], %w[Statistics StatChartWidget]]
  end
end
