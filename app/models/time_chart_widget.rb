class TimeChartWidget < Widget
  
  def name
    [columns, advanced_search.presence, table, grouping.presence || 'daily'].compact.join(" | ")
  end
  
end
