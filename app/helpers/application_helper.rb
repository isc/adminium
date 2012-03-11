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
        if value.length > 100
          value.truncate(100) + content_tag(:a, content_tag(:i, nil, class:'icon-plus-sign'), data: {content:value}, class: 'text-more')
        else
          value
        end
      end
    when ActiveSupport::TimeWithZone
      display_datetime(value)
    when Fixnum, BigDecimal
      number_with_delimiter value
    else
      value
    end
  end

  def display_datetime(value, format=nil)
    return if nil
    format ||= global_settings.datetime_format
    if format.to_sym == :time_ago_in_words
      time_ago_in_words(value) + ' ago'
    else
      l(value, :format => format.to_sym)
    end
  end

  def active_or_not controller_name
    'active' if controller_name == controller.controller_name
  end

end
