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

  def display_attribute wrapper_tag, item, key, value
    if key =~ /_id$/ && item.class.reflections.keys.find {|assoc| assoc.to_s == key.gsub(/_id$/, '') }
      assoc_name = key.gsub /_id$/, ''
      content = link_to "#{assoc_name.humanize} ##{value}", resource_path(item.class.reflections[assoc_name.to_sym].table_name, value)
      css_class = 'foreignkey'
    elsif enum_values = item.class.settings.enum_values_for(key)
      content = link_to (enum_values.invert[value] || value), resources_path(item.class.table_name, where: {key => value}),
        :class => 'label label-info'
      css_class = 'enum'
    else
      css_class, content = display_value value, key
    end
    content_tag wrapper_tag, content, class: css_class
  end
  
  def display_value value, key
    css_class = value.class.to_s.parameterize
    content = case value
    when String
      if value.empty?
        css_class = 'emptystring'
        'empty string'
      else
        if value.length > 100
          (h(value.truncate(100)) + content_tag(:a, content_tag(:i, nil, class:'icon-plus-sign'), data: {content:html_escape(value), title:key}, class: 'text-more')).html_safe
        else
          value
        end
      end
    when ActiveSupport::TimeWithZone
      display_datetime value
    when Fixnum, BigDecimal
      number_with_delimiter value
    when nil
      'null'
    else
      value.to_s
    end
    [css_class, content]
  end

  def display_datetime(value, format=nil)
    return if nil
    format ||= global_settings.datetime_format
    if format.to_sym == :time_ago_in_words
      time_ago_in_words(value) + ' ago'
    else
      l(value, format: format.to_sym)
    end
  end

  def active_or_not controller_name
    'active' if controller_name == controller.controller_name
  end

end
