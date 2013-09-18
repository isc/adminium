class TimeChartWidget < Widget
  
  def name
    [columns, advanced_search.presence, table, grouping].compact.join(" | ")
  end
  
end
