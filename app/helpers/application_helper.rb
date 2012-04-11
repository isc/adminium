module ApplicationHelper

  def flash_class(level)
    case level
    when :notice then 'info'
    when :error then 'error'
    when :alert then 'warning'
    end
  end

  def display_attribute wrapper_tag, item, key
    value = item[key]
    if value && item.class.foreign_key?(key)
      content = display_belongs_to item, key, value
      css_class = 'foreignkey'
    elsif enum_values = item.class.settings.enum_values_for(key)
      content = link_to (enum_values.invert[value.to_s] || value), resources_path(item.class.table_name, where: {key => value}),
        :class => 'label label-info'
      css_class = 'enum'
    elsif item.class.settings.columns[:serialized].include? key
      css_class, content = 'serialized', content_tag(:pre, value.inspect, :class => 'sh_ruby')
    else
      css_class, content = display_value value, key
    end
    content_tag wrapper_tag, content, class: css_class
  end

  # FIXME n+1 queries perf issue with label_column option
  def display_belongs_to item, key, value
    assoc_name = key.gsub /_id$/, ''
    reflection = item.class.reflections[assoc_name.to_sym]
    if reflection.options[:polymorphic]
      assoc_type = item.send key.gsub(/_id/, '_type')
      class_name, path = assoc_type, resource_path(assoc_type.tableize, value)
    else
      class_name, path = assoc_name.classify, resource_path(reflection.table_name, value)
    end
    foreign_class = @generic.table(class_name.tableize)
    label_column = foreign_class.settings.label_column
    label = label_column.present? ? foreign_class.find(value).adminium_label : "#{class_name} ##{value}"
    link_to label, path
  end

  def display_value value, key
    css_class = value.class.to_s.parameterize
    content = case value
    when String
      if value.empty?
        css_class = 'emptystring'
        'empty string'
      else
        truncate_with_popover value, key
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

  def truncate_with_popover value, key
    if value.length > 100
      popover = content_tag :a, content_tag(:i, nil, class:'icon-plus-sign'),
        data: {content:h(value), title:key}, class: 'text-more'
      (h(value.truncate(100)) + popover).html_safe
    else
      value
    end
  end

  def display_datetime(value, format=nil)
    return if nil
    format ||= global_settings.datetime_format
    if format.to_sym == :time_ago_in_words
      str = time_ago_in_words(value) + ' ago'
      content_tag('span', str, title: l(value, format: :long), rel: 'tooltip')
    else
      l(value, format: format.to_sym)
    end
  end

  def active_or_not controller_name
    'active' if controller_name == controller.controller_name
  end

  def display_filter filter
    filter.map do |f|
      "<strong>#{f["column"]}</strong> #{f["operator"]} <i>#{f["operand"]}</i>"
    end.join("<br/>")
  end

end
