module WidgetsHelper

  def widget_query_path widget, opts = {}
    options = {asearch: widget.advanced_search.presence, order: widget.order}
    options[:widget_id] = widget.id if opts[:with_id]
    if widget.is_a? TableWidget
      resources_path(widget.table, options)
    else
      if opts[:with_id]
        options[:column] = widget.columns
        options[:type] = widget.class.to_s.gsub("Widget", "")
        if widget.is_a? TimeChartWidget
          options[:grouping] = widget.grouping
        end
        chart_resources_path(widget.table, options)
      else
        resources_path widget.table, options
      end
    end
  end
end
