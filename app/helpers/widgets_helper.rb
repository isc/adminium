module WidgetsHelper

  def widget_query_path widget, opts = {}
    options = {asearch: widget.advanced_search.presence, order: widget.order}
    options[:widget_id] = widget.id if opts[:with_id]
    resources_path(widget.table, options)
  end

end
