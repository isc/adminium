class PieChartWidget < Widget
  def name
    [columns, advanced_search.presence, table].compact.join(' | ')
  end
end
