module ResourcesHelper

  def header_link original_key
    key = original_key.to_s
    display_name = resource.column_display_name(original_key)
    if key.include? '.'
      parts = key.split('.')
      parts[0] = parts.first.tableize
      key = parts.join('.')
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
    return display_associated_column item, key, wrapper_tag, resource if key.to_s.include? '.'
    return display_associated_count item, key, wrapper_tag, resource if key.to_s.starts_with? 'has_many/'
    value = item[key]
    if value && resource.foreign_key?(key)
      content = display_belongs_to item, key, value, resource
      css_class = 'foreignkey'
    elsif enum_values = resource.enum_values_for(key)
      is_editable = true
      if value.nil?
        content, css_class = 'null', 'nilclass'
      else
        label = enum_values[value.to_s].try(:[], 'label') || value
        user_defined_bg = enum_values[value.to_s].try(:[], 'color')
        user_defined_bg = "background-color: #{user_defined_bg}" if user_defined_bg.present?
        # FIXME the link is screwed rendered in return of an in-place edit ; links to show instead of index
        content = link_to label, params.merge(where: {(original_key || key) => value}), class: 'label label-info', style: user_defined_bg
        css_class = 'enum'
      end
    elsif value.present? && resource.columns[:serialized].include?(key)
      content = value.present? ? (YAML.load(value).inspect rescue value) : value
      css_class, content = 'serialized', content_tag(:pre, content, class: 'sh_ruby')
    else
      css_class, content = display_value item, key, resource
      is_editable = true
    end
    opts = {class: css_class}
    is_editable = false if resource.primary_key == key || key == 'updated_at' || relation || resource.primary_key.nil?
    if is_editable
      opts.merge! "data-column-name" => key
      opts.merge! "data-raw-value" => item[key].to_s unless item[key].is_a?(String) && css_class != 'enum'
    end
    column_content_tag wrapper_tag, content, opts
  end

  def display_associated_column item, key, wrapper_tag, resource
    parts = key.to_s.split('.')
    assoc_info = resource.associations[:belongs_to][parts.first.to_sym]
    item = @associated_items[parts.first.to_sym].find {|i| i[assoc_info[:primary_key]] == item[assoc_info[:foreign_key]]}
    return column_content_tag wrapper_tag, 'null', class: 'nilclass' if item.nil?
    display_attribute wrapper_tag, item, parts.second, resource_for(assoc_info[:referenced_table]), true, key
  end

  def display_associated_count item, key, wrapper_tag, resource
    value = item[key]
    return column_content_tag wrapper_tag, '', class: 'hasmany' if value.nil?
    key = key.to_s.gsub 'has_many/', ''
    foreign_key_name = resource.associations[:has_many].find {|name, assoc| name.to_s == key }.second[:foreign_key]
    foreign_key_value = item[resource.primary_key]
    content = link_to value, resources_path(key, where: {foreign_key_name => foreign_key_value}), class: 'badge badge-warning'
    column_content_tag wrapper_tag, content, class: 'hasmany'
  end

  def display_belongs_to item, key, value, resource
    assoc_name, assoc = resource.associations[:belongs_to].find {|_, info| info[:foreign_key] == key}
    if assoc[:polymorphic]
      assoc_type = item[key.to_s.gsub(/_id/, '_type').to_sym]
      return value if assoc_type.blank?
      referenced_table = assoc_type.to_s.tableize
      begin
        foreign_resource = resource_for referenced_table
      rescue Generic::TableNotFoundException
        return value
      end
    else
      foreign_resource, referenced_table = (resource_for assoc[:referenced_table]), assoc[:referenced_table]
    end
    label_column = foreign_resource.label_column
    if label_column.present?
      item = if @associated_items && !assoc[:polymorphic]
        @associated_items[foreign_resource.table].find {|i| i[assoc[:primary_key]] == value}
      else
        foreign_resource.find value
      end
      return value if item.nil?
      label = foreign_resource.item_label item
    else
      object_name = referenced_table.to_s.singularize.humanize
      label = "#{object_name} ##{value}"
    end
    link_to label, resource_path(referenced_table, value)
  end
  
  def display_associated_items resource, item, assoc_name
    items = resource.fetch_associated_items @item, assoc_name, 5
    resource = resource_for assoc_name
    items.map do |item|
      link_to resource.item_label(item), resource_path(resource.table, item[resource.primary_key])
    end.join(", ")
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
        offset + collection.current_page_record_count,
        collection.pagination_record_count
      ]
    end
  end

  def unescape_name_value_pair param
    [CGI.unescape(param.split('=').first), CGI.unescape(param.split('=').last)]
  end

  def options_for_custom_columns resource
    res = [['belongs_to', resource.associations[:belongs_to].map{|name, assoc|[name, assoc[:table]] unless assoc[:polymorphic]}.compact]]
    res << ['has_many', resource.associations[:has_many].map{|name, assoc|["#{name.to_s.humanize} count", name]}]
    grouped_options_for_select res
  end

end