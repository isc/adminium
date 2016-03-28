class StatChartWidget < Widget
  def name
    ["statistics of #{columns}", advanced_search.presence, table].compact.join(' | ')
  end
end
