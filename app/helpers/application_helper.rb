module ApplicationHelper

  def flash_class(level)
    case level
    when :notice then 'info'
    when :error then 'error'
    when :alert then 'warning'
    end
  end

  def display_attribute wrapper_tag, item, key
    if key.include? "."
      parts = key.split('.')
      item = item.send(parts.first)
      return column_content_tag wrapper_tag, 'null', class: 'nilclass' if item.nil?
      return display_attribute wrapper_tag, item, parts.second
    end
    value = item[key]
    if value && item.class.foreign_key?(key)
      content = display_belongs_to item, key, value
      css_class = 'foreignkey'
    elsif enum_values = item.class.settings.enum_values_for(key)
      if value.nil?
        content, css_class = 'null', 'nilclass'
      else
        content = link_to (enum_values.invert[value.to_s] || value),
          resources_path(item.class.table_name, where: {key => value}),
          :class => 'label label-info'
        css_class = 'enum'
      end
    elsif item.class.settings.columns[:serialized].include? key
      css_class, content = 'serialized', content_tag(:pre, value.inspect, :class => 'sh_ruby')
    else
      css_class, content = display_value item, key
    end
    column_content_tag wrapper_tag, content, class: css_class
  end

  def column_content_tag wrapper_tag, content, opts
    opts[:class] = "column #{opts[:class]}"
    content_tag wrapper_tag, content, opts
  end

  # FIXME n+1 queries perf issue with label_column option

  def foreign_class clazz, key
    assoc_name = key.gsub /_id$/, ''
    reflection = clazz.reflections[assoc_name.to_sym]
    @generic.table(assoc_name.classify.tableize)
  end

  def foreign_class_and_path item, key, value
    assoc_name = key.gsub /_id$/, ''
    reflection = item.class.reflections[assoc_name.to_sym]
    if reflection.options[:polymorphic]
      assoc_type = item.send key.gsub(/_id/, '_type')
      class_name, path = assoc_type, resource_path(assoc_type.to_s.tableize, value)
    else
      class_name, path = assoc_name.classify, resource_path(reflection.table_name, value)
    end
    foreign_clazz = @generic.table(class_name.tableize)
    [class_name, foreign_clazz, path]
  end

  def display_belongs_to item, key, value
    assoc_name = key.gsub /_id$/, ''
    reflection = item.class.reflections[assoc_name.to_sym]
    if reflection.options[:polymorphic]
      assoc_type = item.send key.gsub(/_id/, '_type')
      class_name, path = assoc_type, resource_path(assoc_type.to_s.tableize, value)
    else
      class_name, path = assoc_name.classify, resource_path(reflection.table_name, value)
    end
    foreign_clazz = @generic.table(class_name.tableize)
    label_column = foreign_clazz.settings.label_column
    if label_column.present?
      item = foreign_clazz.where(foreign_clazz.primary_key => value).first
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
    when ActiveSupport::TimeWithZone
      display_datetime value, column: key, clazz: item.class
    when Fixnum, BigDecimal
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
        data: {content:h(value), title:key}, class: 'text-more'
      (h(value.truncate(100)) + popover).html_safe
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

  def display_datetime_control_group opts={}
    opts[:label] ||= "DateTime format"
    d = Time.now
    formats = (opts[:kind] == :date) ? configatron.settings.date : configatron.settings.date
    datas = formats.map{|f|[display_datetime(d, format: f),f.to_s]}
    if opts[:allow_blank]
      datas = [[opts[:allow_blank], '']] + datas
    end
    content_tag :div, class: "control-group" do
      l = content_tag(:label, opts[:label], class: "control-label")
      l + content_tag(:div, class: "controls") do
        content_tag(:select, name: opts[:input_name]) do
          options_for_select(datas, opts[:selected])
        end
      end
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

  def spinner_tag
    content_tag :div, :id => 'bowlG' do
      content_tag :div, :id =>'bowl_ringG' do
        content_tag :div, :class => 'ball_holderG' do
          content_tag :div, :class => 'ballG' do
          end
        end
      end
    end
  end

  def format_param_for_removal k, v
    "#{CGI.escape("where[#{k}]")}=#{CGI.escape(v)}"
  end

end
