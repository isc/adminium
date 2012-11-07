module ResourcesHelper

  def header_link original_key
    key = original_key
    if key.include? '.'
      parts = key.split('.')
      parts[0] = parts.first.tableize
      key = parts.join('.')
    end
    if key.starts_with? 'has_many/'
      key = "\"#{key}\""
    end
    params[:order] ||= 'id'
    if params[:order] == key
      order = "#{key} desc"
      title = "descend by #{key}"
    else
      order = key
      title = "ascend by #{key}"
    end
    res = ""
    {'up' => key, 'down' => "#{key} desc"}.each do |direction, dorder|
      active = dorder == params[:order] ? 'active' : nil
      dtitle = direction == 'up' ? "ascend by #{key}" : "descend by #{key}"
      res << link_to(params.merge(order: dorder), title: dtitle, rel: 'tooltip') do
        content_tag('i', '', class: "icon-chevron-#{direction} #{active}")
      end
    end
    res << (link_to clazz.column_display_name(original_key), params.merge(order:order), title: title, rel:'tooltip')
  end

  def display_attribute wrapper_tag, item, key, relation = false
    is_editable = nil
    return display_associated_column item, key, wrapper_tag if key.include? '.'
    return display_associated_count item, key, wrapper_tag if key.starts_with? 'has_many/'
    value = item[key]
    if value && item.class.foreign_key?(key)
      content = display_belongs_to item, key, value
      css_class = 'foreignkey'
    elsif enum_values = item.class.settings.enum_values_for(key)
      is_editable = true
      if value.nil?
        content, css_class = 'null', 'nilclass'
      else
        begin # link generation fails if rendered via json controller update
        label = enum_values[value.to_s].try(:[], 'label') || value
        user_defined_bg = enum_values[value.to_s].try(:[], 'color')
        user_defined_bg = "background-color: #{user_defined_bg}" if user_defined_bg.present?
        content = link_to label, params.merge(where: {key => value}), :class => 'label label-info', :style => user_defined_bg
        rescue
          content = content_tag :span, label, :class => 'label label-info', :style => user_defined_bg
        end
        css_class = 'enum'
      end
    elsif item.class.settings.columns[:serialized].include? key
      css_class, content = 'serialized', content_tag(:pre, value.inspect, :class => 'sh_ruby')
    else
      css_class, content = display_value item, key
      is_editable = true
    end
    opts = {class: css_class}
    is_editable = false if item.class.primary_key == key || key == 'updated_at' || relation
    if is_editable
      opts.merge! "data-column-name" => key
      opts.merge! "data-raw-value" => item[key].to_s unless item[key].is_a?(String) && css_class != 'enum'
    end
    column_content_tag wrapper_tag, content, opts
  end

  def display_associated_column item, key, wrapper_tag
    parts = key.split('.')
    item = item.send(parts.first)
    return column_content_tag wrapper_tag, 'null', class: 'nilclass' if item.nil?
    display_attribute wrapper_tag, item, parts.second, true
  end

  def display_associated_count item, key, wrapper_tag
    value = item[key]
    return column_content_tag wrapper_tag, '', class: 'hasmany' if value.nil?
    key = key.gsub 'has_many/', ''
    foreign_key_name = item.class.reflections.values.find {|r| r.name.to_s == key }.foreign_key
    foreign_key_value = item[item.class.primary_key]
    content = link_to value, resources_path(key, where: {foreign_key_name => foreign_key_value}), class: 'badge badge-warning'
    column_content_tag wrapper_tag, content, class: 'hasmany'
  end

  def display_belongs_to item, key, value
    reflection = item.class.reflections.values.find {|r| r.foreign_key == key}
    if reflection.options[:polymorphic]
      assoc_type = item.send key.gsub(/_id/, '_type')
      class_name, path = assoc_type, resource_path(assoc_type.to_s.tableize, value)
      foreign_clazz = @generic.table class_name.tableize
    else
      class_name, path = reflection.klass.original_name, resource_path(reflection.table_name, value)
      # reflection.klass is a leftover class that should have been garbage collected
      # and has settings already loaded in it that may be outdated
      foreign_clazz = @generic.table(reflection.klass.table_name)
    end
    label_column = foreign_clazz.settings.label_column
    if label_column.present?
      item = if reflection.options[:polymorphic]
        foreign_clazz.where(foreign_clazz.primary_key => value).first
      else
        item.send reflection.name
      end
      return value if item.nil?
      label = item.adminium_label
    else
      label = "#{class_name} ##{value}"
    end
    link_to label, path
  end

  def display_value item, key
    value = item[key]
    css_class = value.class.to_s.parameterize
    content = case value
    when String
      if value.empty?
        css_class = 'emptystring'
        'empty string'
      else
        truncate_with_popover value, key
      end
    when ActiveSupport::TimeWithZone, Date
      display_datetime value, column: key, clazz: item.class
    when Fixnum, BigDecimal, Float
      display_number key, item
    when TrueClass, FalseClass
      display_boolean key, item
    when nil
      'null'
    else
      value.to_s
    end
    [css_class, content]
  end

  def display_boolean key, item
    value = item[key]
    options = item.class.settings.column_options(key)
    if options["boolean_#{value}"].present?
      options["boolean_#{value}"]
    else
      value.to_s
    end
  end

  def display_number key, item
    value = item[key]
    options = item.class.settings.column_options(key)
    number_options = {:unit => "", :significant => true}
    opts = [:unit, :delimiter, :separator, :precision]
    if value.is_a? Fixnum
      number_options[:precision] = 0
    else
      opts.push :precision
    end
    opts.each do |u|
      number_options[u] = options["number_#{u}"] if options["number_#{u}"].present?
    end
    number_options[:format] = "%n%u" if options['number_unit_append'].present?
    number_options[:precision] = number_options[:precision].to_i if number_options[:precision]
    number_to_currency value, number_options
  end

  def truncate_with_popover value, key
    if value.length > 100
      popover = content_tag :a, content_tag(:i, nil, class:'icon-plus-sign'),
        data: {content:ERB::Util.h(value), title:key}, class: 'text-more'
      (ERB::Util.h(value.truncate(100)) + popover).html_safe
    else
      value
    end
  end

  def display_datetime(value, opts={})
    return if value == nil
    if opts[:column] && opts[:clazz]
      opts[:format] = opts[:clazz].settings.column_options(opts[:column])['format']
      opts[:format] = nil if opts[:format].blank?
    end
    opts[:format] ||= global_settings.datetime_format
    if opts[:format].to_sym == :time_ago_in_words
      str = time_ago_in_words(value) + ' ago'
      content_tag('span', str, title: l(value, format: :long), rel: 'tooltip')
    else
      l(value, format: opts[:format].to_sym)
    end
  end

  def column_content_tag wrapper_tag, content, opts
    opts[:class] = "column #{opts[:class]}"
    content_tag wrapper_tag, content, opts
  end
  
  def boolean_input_options clazz, key
    column_options = clazz.settings.column_options(key)
    opts = [[column_options['boolean_true'].presence || 'Yes', true], [column_options['boolean_false'].presence || 'No', false]]
    {as: :select, collection: opts}
  end

  def page_entries_info(collection, options = {})
    entry_name = options[:entry_name] || (collection.empty? ? 'entry' : collection.first.class.name.underscore.sub('_', ' '))
    if collection.num_pages < 2
      case collection.total_count
      when 0; "0 #{entry_name.pluralize}"
      when 1; "<b>1</b> #{entry_name}"
      else;   "<b>#{collection.total_count}</b> #{entry_name.pluralize}"
      end
    else
      offset = (collection.current_page - 1) * collection.limit_value
      %{<b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b>} % [
        offset + 1,
        offset + collection.limit_value,
        collection.total_count
      ]
    end
  end
  
  def unescape_name_value_pair param
    [CGI.unescape(param.split('=').first), CGI.unescape(param.split('=').last)]
  end
  
  def options_for_custom_columns clazz
    res = [['belongs_to', clazz.reflect_on_all_associations(:belongs_to).map{|r|[r.name, r.plural_name] unless r.options[:polymorphic]}.compact]]
    res << ['has_many', clazz.reflect_on_all_associations(:has_many).map{|r|["#{r.name.to_s.humanize} count", r.name]}]
    grouped_options_for_select res
  end

end