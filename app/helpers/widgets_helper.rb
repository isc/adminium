module WidgetsHelper
  def widget_query_path widget, opts = {}
    options = {asearch: widget.advanced_search.presence, order: widget.order}
    options[:widget_id] = widget.id if opts[:with_id]
    if widget.is_a?(TableWidget) || !options[:with_id]
      resources_path widget.table, options
    else
      options[:column] = widget.columns
      options[:type] = widget.class.to_s.gsub('Widget', '')
      options[:grouping] = widget.grouping if widget.is_a? TimeChartWidget
      chart_resources_path(widget.table, options)
    end
  end
end
