module WidgetsHelper

  def widget_query_path widget, opts = {}
    options = {asearch: widget.advanced_search.presence, order: widget.order}
    options[:widget_id] = widget.id if opts[:with_id]
    if widget.is_a? TableWidget
      resources_path(widget.table, options)
    elsif widget.is_a? TimeChartWidget
      if opts[:with_id]
        options[:column] = widget.columns
        options[:grouping] = widget.grouping
        time_chart_resources_path(widget.table, options)
      else
        resources_path widget.table, options
      end
    end
  end

end
