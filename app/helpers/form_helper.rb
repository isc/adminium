module FormHelper
  def input resource, item, name, required_constraints
    input_name, input_value, input_id = "#{resource.table}[#{name}]", item[name], "#{resource.table}_#{name}"
    input_value = resource.default_value name if required_constraints && input_value.nil?
    input_type, options = default_input_type(resource, name, input_value)
    required = required_constraints && resource.required_column?(name)
    input_options = {id: input_id, required: required, class: 'form-control'}
    input_options[:'data-null-value'] = true if input_value.nil?
    return '...' unless input_type
    case input_type
    when :select
      select_tag input_name, options_for_select(options, input_value), input_options.merge(include_blank: true)
    when :date, :datetime, :time
      datetime_input input_options, input_value, input_name, input_type
    when :float_field
      number_field_tag input_name, input_value, input_options.merge(step: 'any')
    else
      send "#{input_type}_tag", input_name, input_value, input_options
    end
  end

  def default_input_type resource, name, value
    enum_values = resource.enum_values_for name
    return :select, enum_values.to_a.map {|v| [v[1]['label'], v[0]]} if enum_values
    info = resource.column_info name
    case info[:type]
    when :integer then :number_field
    when :decimal, :float then :float_field
    when :timestamp, :datetime then :datetime
    when :date then :date
    when :time then :time
    when :varchar_array then :text_area
    when :boolean then [:select, boolean_input_options(resource, name)]
    when :string, nil
      return :text_area if info[:db_type] == 'text'
      case name.to_s
      when /password/  then :password_field
      when /time_zone/ then [:select, time_zone_options_for_select(value)]
      when /email/     then :email_field
      when /phone/     then :telephone_field
      else
        :text_field
      end
    end
  end

  def datetime_input input_options, input_value, input_name, input_type
    input_options[:class] = 'datepicker form-control'
    res = ''.html_safe
    if %i(date datetime).include? input_type
      input_value = Time.now if input_value.is_a? Sequel::SQL::Constant
      date_value = input_value&.to_date || ''
      res << (date_field_tag "#{input_name}[date]", date_value, input_options)
    end
    if %i(datetime time).include? input_type
      options = {class: 'form-control', include_blank: true}
      hour = input_value.strftime '%H' if input_value
      minute = input_value.strftime '%M' if input_value
      res << (' '.html_safe + select_tag("#{input_name}[4i]", options_for_select(('00'...'24'), hour), options.clone))
      res << (' : '.html_safe + select_tag("#{input_name}[5i]", options_for_select(('00'...'60'), minute), options))
    end
    content_tag :div, res, class: 'form-inline'
  end

  def belongs_to_select_tag resource, item, foreign_resource, name
    options = foreign_resource.query.select(foreign_resource.primary_keys).order(foreign_resource.label_column.try(:to_sym) || foreign_resource.primary_keys.first)
    options = options.select_append(foreign_resource.label_column.to_sym) if foreign_resource.label_column
    select_tag "#{resource.table}[#{name}]", options_for_select(options.all.map {|i| [foreign_resource.item_label(i), foreign_resource.primary_key_value(i)]}, item[name]), include_blank: true, class: 'form-control'
  end
end
