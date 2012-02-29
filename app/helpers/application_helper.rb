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
    res = content_tag 'i', '', class: icon
    res << (link_to key.humanize, resources_path(params[:table], order:order))
  end
  
  def display_value value
    case value
    when String
      if value.empty?
        'empty string'
      else
        value.truncate(100)
      end
    when ActiveSupport::TimeWithZone
      l(value, :format => Settings::Global.datetime_format.to_sym)
    when Fixnum, BigDecimal
      number_with_delimiter value
    else
      value
    end
  end
  
  def active_or_not controller_name
    'active' if controller_name == controller.controller_name
  end
  
end
