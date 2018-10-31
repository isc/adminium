module ResourcesHelper
  def header_link original_key
    key = original_key.to_s
    display_name = resource.column_display_name original_key
    params[:order] = params[:order] || resource.default_order
    if params[:order] == key
      order = "#{key} desc"
      ascend = false
    else
      order = key
      ascend = true
    end
    res = ''
    {'up' => key, 'down' => "#{key} desc"}.each do |direction, dorder|
      active = dorder == params[:order] ? 'active' : nil
      url = url_for(whitelisted_params.merge(order: dorder))
      title = sort_title(display_name, direction == 'up', original_key)
      res << link_to(url, title: title, class: "sort-#{direction}") do
        content_tag('i', '', class: "fa fa-chevron-#{direction} #{active}")
      end
    end
    res << (link_to display_name, whitelisted_params.merge(order: order), title: sort_title(display_name, ascend, original_key))
  end

  def sort_title display_name, ascend, original_key
    a, z = if resource.number_column?(original_key) || original_key.to_s.starts_with?('has_many/')
             [0, 9]
           else
             %w(A Z)
           end
    if ascend
      "Sort by #{display_name} #{a} &rarr; #{z}".html_safe
    else
      "Sort by #{display_name} #{z} &rarr; #{a}".html_safe
    end
  end

  def display_file wrapper_tag, item, key, resource
    item_pk = resource.primary_key_value item
    column_content_tag wrapper_tag, link_to("Download (#{number_to_human_size(item[key])})", download_resource_path(params[:table], item_pk, key: key)), {}
  end

  def display_attribute wrapper_tag, item, key, resource, original_key = nil
    is_editable, key = nil, key.to_sym
    return display_associated_column item, key, wrapper_tag, resource if key.to_s.include? '.'
    return display_associated_count item, key, wrapper_tag, resource if key.to_s.starts_with? 'has_many/'
    return display_file(wrapper_tag, item, key, resource) if resource.binary_column?(key) && !item[key].nil?
    value = item[key]
    if value && resource.foreign_key?(key)
      content = display_belongs_to item, key, value, resource
      css_class = 'foreignkey'
    elsif (enum_values = resource.enum_values_for(key))
      is_editable = true
      if value.nil?
        content, css_class = 'null', 'nilclass'
      else
        label = enum_values[value.to_s].try(:[], 'label') || value
        user_defined_bg = enum_values[value.to_s].try(:[], 'color')
        user_defined_bg = "background-color: #{user_defined_bg}" if user_defined_bg.present?
        where_hash = {where: (params[:where].try(:permit!) || {}).merge((original_key || key) => value)}
        # FIXME: some params are lost when rendered in return of an in-place edit (update action name)
        link_params = %w(show update).include?(action_name) ? where_hash : whitelisted_params.merge(where_hash)
        content = link_to label, resources_path(params[:table], link_params),
          class: 'label label-info', style: user_defined_bg
        css_class = 'enum'
      end
    elsif value.present? && resource.columns[:serialized].include?(key)
      content = value.present? ? (YAML.safe_load(value).inspect rescue value) : value
      css_class, content = 'serialized', content_tag(:pre, content, class: 'sh_ruby')
    elsif item[key] && (assoc_info = resource.foreign_key_array?(key))
      content = display_foreign_key_array assoc_info[:referenced_table], item[key]
    else
      css_class, content = display_value item, key, resource
      is_editable = true
    end
    opts = {class: css_class}
    is_editable = false if resource.primary_keys.include?(key) || key == 'updated_at' || resource.primary_keys.empty?
    opts['data-editable'] = true if is_editable && user_can?('edit', resource.table)
    opts['data-column-name'] = key
    unless (value.is_a?(String) && css_class != 'enum') || resource.primary_keys.include?(key)
      opts['data-raw-value'] = resource.raw_column_output(item, key)
    end
    opts['data-item-id'] = resource.primary_key_value(item) if resource.table.to_s != params[:table]
    opts['data-column-type'] = resource.column_type(key) if action_name == 'show'
    column_content_tag wrapper_tag, content, opts
  end

  def display_associated_column item, key, wrapper_tag, resource
    parts = key.to_s.split('.')
    assoc_info = resource.belongs_to_association parts.first.to_sym
    item = @associated_items[assoc_info[:referenced_table]]
      .find {|i| i[assoc_info[:primary_key]] == item[assoc_info[:foreign_key]]}
    return column_content_tag wrapper_tag, 'null', class: 'nilclass' if item.nil?
    display_attribute wrapper_tag, item, parts.second, resource_for(assoc_info[:referenced_table]), key
  end

  def display_associated_count item, key, wrapper_tag, resource
    value = item[key]
    return column_content_tag wrapper_tag, '', class: 'hasmany' if value.nil?
    _, table, column = key.to_s.split '/'
    foreign_key_value = resource.primary_key_value item
    path = resources_path(table, where: {column => foreign_key_value})
    content = link_to value, path, class: 'badge badge-warning'
    column_content_tag wrapper_tag, content, class: 'hasmany'
  end

  def display_belongs_to item, key, value, resource
    assoc = resource.belongs_to_association key
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
    return "#{foreign_resource.human_name} ##{value}" unless user_can? 'show', referenced_table
    label_column = foreign_resource.label_column
    if label_column.present?
      item = if @associated_items && !assoc[:polymorphic]
               @associated_items[foreign_resource.table].find {|i| i[assoc[:primary_key]] == value}
             else
               foreign_resource.find_by_primary_key value
             end
      return value if item.nil?
      label = foreign_resource.item_label item
    else
      label = "#{foreign_resource.human_name} ##{value}"
    end
    link_to label, resource_path(referenced_table, value)
  end

  def display_associated_items resource, source_item, assoc
    items = resource.fetch_associated_items source_item, assoc, 5
    resource = resource_for assoc[:table]
    display_items items, resource
  end

  def display_foreign_key_array table, ids
    resource = resource_for table
    items = resource.query.where(resource.primary_keys.first => ids.map(&:to_i)).all
    items = ids.map { |id| items.find {|item| item[resource.primary_keys.first] == id.to_i } || id }
    display_items items, resource
  end

  def display_items items, resource
    items.map do |item|
      if item.is_a?(Hash)
        item_pk = item[resource.primary_keys.first]
        link_to_if item_pk, resource.item_label(item), (resource_path(resource.table, item_pk) if item_pk)
      else
        item
      end
    end.join(', ').html_safe
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
              when Sequel::SQLTime
                display_time value
              when Time, Date
                display_datetime value, column: key, resource: resource
              when Integer, BigDecimal, Float
                display_number key, item, resource
              when TrueClass, FalseClass
                display_boolean key, item, resource
              when Sequel::Postgres::PGArray
                display_array value
              when Sequel::Postgres::HStore
                display_hstore value
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
      css_class = value == true ? 'check' : 'times'
      content_tag :i, nil, class: "fa fa-#{css_class}"
    end
  end

  def display_number key, item, resource, value = nil
    value ||= item[key]
    options = resource.column_options key
    number_options = {unit: '', significant: false}
    opts = %i(unit delimiter separator precision)
    if value.is_a? Integer
      number_options[:precision] = 0
    else
      opts.push :precision
    end
    opts.each do |u|
      number_options[u] = options["number_#{u}"] if options["number_#{u}"].present?
    end
    number_options[:format] = '%n%u' if options['number_unit_append'].present?
    number_options[:precision] = number_options[:precision].to_i if number_options[:precision]
    number_to_currency value, number_options
  end

  def truncate_with_popover value, key
    if @prevent_truncate || value.length < 100
      value
    else
      modal_id = "#{key}-#{Digest::MD5.hexdigest value}"
      modal = modal(key.to_s.humanize, id: modal_id) do |m|
        m.body { content_tag(:pre, ERB::Util.h(value), style: 'white-space: pre-wrap') }
      end
      modal_trigger = content_tag :a, content_tag(:i, nil, class: 'fa fa-plus-circle'),
        data: {toggle: 'modal', target: "##{modal_id}"}, href: '#'
      ERB::Util.h(value.truncate(100)) + modal_trigger + modal
    end
  end

  def display_datetime value, opts = {}
    return if value.nil?
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

  def display_time value
    value.strftime '%H:%M'
  end

  def display_array value
    content_tag(:pre, value, class: 'sh_ruby')
  end

  def display_hstore hash
    content_tag(:table, class: 'hstore table table-condensed table-striped') do
      hash.map do |key, value|
        content_tag(:tr) do
          content_tag(:th, key) + content_tag(:td, value)
        end
      end.join.html_safe
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

  def page_entries_info collection, options = {}
    entry_name = options[:entry_name] || (collection.empty? ? 'entry' : collection.first.class.name.underscore.sub('_', ' '))
    if collection.page_count < 2
      case collection.pagination_record_count
      when 0 then "0 #{entry_name.pluralize}"
      when 1 then "<b>1</b> #{entry_name}"
      else
        "<b>#{collection.pagination_record_count}</b> #{entry_name.pluralize}"
      end
    else
      offset = (collection.current_page - 1) * collection.page_size
      format(%{<b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b>}, offset + 1, offset + collection.current_page_record_count, collection.pagination_record_count)
    end
  end

  def unescape_name_value_pair param
    [CGI.unescape(param.split('=').first), CGI.unescape(param.split('=').last)]
  end

  def columns_options_for_resource resource, options = {}
    res = content_tag :optgroup, label: resource.table.to_s.humanize do
      resource.column_names.map {|name| content_tag(:option, name, value: name)}.join.html_safe
    end
    resource.belongs_to_associations.each do |assoc|
      next if assoc[:polymorphic]
      name = assoc[:foreign_key].to_s
      res << content_tag(:optgroup, label: name.humanize, data: {name: name, kind: 'belongs_to'}) do
        resource_for(assoc[:referenced_table]).column_names
          .map {|column_name| content_tag(:option, column_name, value: column_name)}.join.html_safe
      end
    end
    if options[:has_many]
      resource.has_many_associations.each do |assoc|
        name = assoc[:table].to_s.humanize
        if resource.has_many_associations.many? {|other_assoc| other_assoc[:table] == assoc[:table]}
          name << " as #{assoc[:foreign_key].to_s.humanize}"
        end
        res << content_tag(:optgroup, label: name, data: {name: "#{assoc[:table]}/#{assoc[:foreign_key]}", kind: 'has_many'}) do
          content_tag :option, 'count'
        end
      end
    end
    res
  end

  def generate_chart_path column, type
    chart_resources_path(params.permit(:table, :search, :asearch, :grouping, where: {}, exclude: {})
      .merge(column: column, type: type))
  end

  def column_header_with_metadata resource, name
    if name.to_s['.']
      foreign_key, column = name.to_s.split('.')
      assoc = resource.belongs_to_association foreign_key.to_sym
      table = assoc[:referenced_table]
      type = resource_for(table).column_type column.to_sym
    else
      type = resource.column_type name
      table = resource.table
      column = name
    end
    data = {'column-name' => column, 'column-type' => type, 'table-name' => table}
    data['foreign-key'] = foreign_key if foreign_key
    content_tag(:th, class: 'column_header', data: data) do
      yield table, column
    end
  end

  def page_entries_info_no_record_count items, current_page, page_size
    start = (current_page - 1) * page_size
    if current_page == 1 && items.size < page_size
      [content_tag(:b, items.size), ' record'.pluralize(items.size)].join
    else
      [content_tag(:b, start + 1), ' - ', content_tag(:b, start + items.size)].join
    end
  end
end
