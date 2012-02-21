module ApplicationHelper
  def flash_class(level)
  case level
  when :notice then 'info'
  when :error then 'error'
  when :alert then 'warning'
  end
  end
  
  def header_link key
    order, icon = if params[:order] == key
      ["#{key} desc", 'icon-chevron-up']
    else
      [key, 'icon-chevron-down']
    end
    res = content_tag 'i', '', :class => icon
    res << (link_to key.humanize, resources_path(table:params[:table], order:order))
  end
  
end
