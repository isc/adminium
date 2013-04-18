module ResourcesHelper

  def header_link original_key
    key = original_key.to_s
    display_name = resource.column_display_name(original_key)
    if key.include? '.'
      parts = key.split('.')
      parts[0] = parts.first.tableize
      key = parts.join('.')
    end
    if key.starts_with? 'has_many/'
      key = "\"#{key}\""
    end
    params[:order] = params[:order] || resource.default_order || resource.primary_key
    if params[:order] == key
      order = "#{key} desc"
      ascend = false
    else
      order = key
      ascend = true
    end
    res = ""
    {'up' => key, 'down' => "#{key} desc"}.each do |direction, dorder|
      active = dorder == params[:order] ? 'active' : nil
      res << link_to(params.merge(order: dorder), title: sort_title(display_name, direction=='up', original_key), rel: 'tooltip') do
        content_tag('i', '', class: "icon-chevron-#{direction} #{active}")
      end
    end
    res << (link_to display_name, params.merge(order:order), title: sort_title(display_name, ascend, original_key), rel:'tooltip')
  end
  
  def sort_title display_name, ascend, original_key
    if resource.is_number_column?(original_key) || original_key.to_s.starts_with?('has_many/')
      a,z = [0,9]
    else
      a,z = ['A', 'Z']
    end
    if ascend
      "Sort by #{display_name} #{a} &rarr; #{z}"
    else
      "Sort by #{display_name} #{z} &rarr; #{a}"
    end
  end
  
  def item_attributes_type types, resource
    columns = resource.find_all_columns_for_types(*types).map(&:first)
    columns &= resource.columns[:show]
    columns - [resource.primary_key] - (resource.associations[:belongs_to].values.map {|assoc|assoc[:foreign_key]})
  end

  def display_attribute wrapper_tag, item, key, resource, relation = false, original_key = nil
    is_editable, key = nil, key.to_sym
    return display_associated_column item, key, wrapper_tag if key.to_s.include? '.'
    return display_associated_count item, key, wrapper_tag if key.to_s.starts_with? 'has_many/'
    value = item[key]
    if value && resource.foreign_key?(key)
      content = display_belongs_to item, key, value
      css_class = 'foreignkey'
    elsif enum_values = resource.enum_values_for(key)
      is_editable = true
      if value.nil?
        content, css_class = 'null', 'nilclass'
      else
        begin # link generation fails if rendered via json controller update
          label = enum_values[value.to_s].try(:[], 'label') || value
          user_defined_bg = enum_values[value.to_s].try(:[], 'color')
          user_defined_bg = "background-color: #{user_defined_bg}" if user_defined_bg.present?
          content = link_to label, params.merge(where: {(original_key || key) => value}), :class => 'label label-info', :style => user_defined_bg
        rescue
          content = content_tag :span, label, :class => 'label label-info', :style => user_defined_bg
        end
        css_class = 'enum'
      end
    elsif resource.columns[:serialized].include? key
      css_class, content = 'serialized', content_tag(:pre, value.inspect, :class => 'sh_ruby')
    else
      css_class, content = display_value item, key, resource
      is_editable = true
    end
    opts = {class: css_class}
    is_editable = false if resource.primary_key == key || key == 'updated_at' || relation
    if is_editable
      opts.merge! "data-column-name" => key
      opts.merge! "data-raw-value" => item[key].to_s unless item[key].is_a?(String) && css_class != 'enum'
    end
    column_content_tag wrapper_tag, content, opts
  end

  def display_associated_column item, key, wrapper_tag
    parts = key.to_s.split('.')
    item = item.send "_adminium_#{parts.first}"
    return column_content_tag wrapper_tag, 'null', class: 'nilclass' if item.nil?
    display_attribute wrapper_tag, item, parts.second, true, [item.class.table_name, parts.second].join('.')
  end

  def display_associated_count item, key, wrapper_tag
    value = item[key]
    return column_content_tag wrapper_tag, '', class: 'hasmany' if value.nil?
    key = key.gsub 'has_many/', ''
    foreign_key_name = item.class.reflections.values.find {|r| r.original_name.to_s == key }.foreign_key
    foreign_key_value = item[item.class.primary_key]
    content = link_to value, resources_path(key, where: {foreign_key_name => foreign_key_value}), class: 'badge badge-warning'
    column_content_tag wrapper_tag, content, class: 'hasmany'
  end

  def display_belongs_to item, key, value
    reflection = item.class.reflections.values.find {|r| r.foreign_key == key}
    if reflection.options[:polymorphic]
      assoc_type = item.send key.gsub(/_id/, '_type')
      return value if assoc_type.blank?
      class_name, path = assoc_type, resource_path(assoc_type.to_s.tableize, value)
      begin
        foreign_clazz = @generic.table class_name.to_s.tableize
      rescue Generic::TableNotFoundException
        return value
      end
    else
      class_name, path = reflection.klass.original_name, resource_path(reflection.table_name, value)
      # reflection.klass is a leftover class that should have been garbage collected
      # and has settings already loaded in it that may be outdated
      foreign_clazz = @generic.table(reflection.klass.table_name)
    end
    label_column = foreign_clazz.resource.label_column
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
  
  def display_item item
    label = item.adminium_label || "##{item[item.class.primary_key]}"
    link_to label, resource_path(item.class.table_name, item)
  end

  def display_value item, key, resource
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
    when Time, Date
      display_datetime value, column: key, resource: resource
    when Fixnum, BigDecimal, Float
      display_number key, item, resource
    when TrueClass, FalseClass
      display_boolean key, item, resource
    when nil
      'null'
    else
      value.to_s
    end
    [css_class, content]
  end

  def display_boolean key, item, resource
    value = item[key]
    options = resource.column_options key
    if options["boolean_#{value}"].present?
      options["boolean_#{value}"]
    else
      value.to_s
    end
  end

  def display_number key, item, resource, value = nil
    value ||= item[key]
    options = resource.column_options key
    number_options = {unit: "", significant: true}
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
    if @prevent_truncate || value.length < 100
      value
    else
      popover = content_tag :a, content_tag(:i, nil, class:'icon-plus-sign'),
        data: {content:ERB::Util.h(value), title:key}, class: 'text-more'
      (ERB::Util.h(value.truncate(100)) + popover).html_safe
    end
  end

  def display_datetime(value, opts={})
    return if value == nil
    if opts[:column] && opts[:resource]
      opts[:format] = opts[:resource].column_options(opts[:column])['format']
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

  def boolean_input_options resource, key
    column_options = resource.column_options key
    [[column_options['boolean_true'].presence || 'Yes', true], [column_options['boolean_false'].presence || 'No', false]]
  end

  def page_entries_info(collection, options = {})
    entry_name = options[:entry_name] || (collection.empty? ? 'entry' : collection.first.class.name.underscore.sub('_', ' '))
    if collection.page_count < 2
      case collection.pagination_record_count
      when 0; "0 #{entry_name.pluralize}"
      when 1; "<b>1</b> #{entry_name}"
      else;   "<b>#{collection.pagination_record_count}</b> #{entry_name.pluralize}"
      end
    else
      offset = (collection.current_page - 1) * collection.page_size
      %{<b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b>} % [
        offset + 1,
        offset + collection.page_size,
        collection.pagination_record_count
      ]
    end
  end

  def unescape_name_value_pair param
    [CGI.unescape(param.split('=').first), CGI.unescape(param.split('=').last)]
  end

  def options_for_custom_columns resource
    return # refactoring in progress
    res = [['belongs_to', clazz.reflect_on_all_associations(:belongs_to).map{|r|[r.original_name, r.original_plural_name] unless r.options[:polymorphic]}.compact]]
    res << ['has_many', clazz.reflect_on_all_associations(:has_many).map{|r|["#{r.original_name.to_s.humanize} count", r.original_name]}]
    grouped_options_for_select res
  end

end