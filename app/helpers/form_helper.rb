module FormHelper

  def input resource, item, name, input_class
    input_name, input_value, input_id = "#{resource.table}[#{name}]", item[name], "#{resource.table}_#{name}"
    input_type, options = default_input_type(resource, name, input_value)
    input_options = {id: input_id, required: resource.required_column?(name), class: input_class}
    input_options.merge!(readonly: true) if resource.column_info(name)[:primary_key]
    return "..." unless input_type
    case input_type
    when :select
      input_options.delete :class
      select_tag input_name, options_for_select(options, input_value), input_options.merge(include_blank: true)
    when :date, :datetime
      datetime_input input_options, input_value, input_name, input_id, input_type
    else
      send "#{input_type}_tag", input_name, input_value, input_options
    end
  end

  def default_input_type resource, name, value
    info = resource.column_info name
    if enum_values = resource.enum_values_for(name)
      return :select, enum_values.to_a.map {|v| [v[1]['label'], v[0]]}
    end
    case info[:type]
    when :integer, :decimal
      :number_field
    when :timestamp, :datetime
      :datetime
    when :date
      :date
    when :boolean
      [:select, boolean_input_options(resource, name)]
    when :string, nil
      return :text_area if info[:db_type] == 'text'
      case name.to_s
      when /password/  then :password_field
      when /time_zone/ then [:select, time_zone_options_for_select(value)]
      when /country/   then [:select, country_options_for_select(value)]
      when /email/     then :email_field
      when /phone/     then :telephone_field
      when /url/       then :url_field
      else
        :text_field
      end
    else
      nil
    end
  end

  def datetime_input input_options, input_value, input_name, input_id, input_type
    input_options[:class] = 'datepicker span2'
    value_string = input_value ? input_value.to_date.strftime('%m/%d/%Y') : ''
    res = text_field_tag nil, value_string, input_options
    input_options[:class] = 'span2'
    [:year, :month, :day].each_with_index do |type, i|
      v = input_value ? input_value.try(type).to_s : ''
      res << (hidden_field_tag "#{input_name}[#{i+1}i]", v, id: "#{input_id}_#{i+1}i")
    end
    if input_type == :datetime
      hour = input_value.try(:hour).to_s.rjust(2, '0')
      res << (' '.html_safe + select_tag("#{input_name}[4i]", options_for_select(('00'...'24'), hour), class: 'span1'))
      minute = input_value.try(:min).to_s.rjust(2, '0')
      res << (' : '.html_safe + select_tag("#{input_name}[5i]", options_for_select(('00'...'60'), minute), class: 'span1'))
    end
    res
  end
  
  def belongs_to_select_tag resource, item, foreign_resource, name
    options = foreign_resource.query.select(foreign_resource.primary_keys).order(foreign_resource.label_column.try(:to_sym) || foreign_resource.primary_keys.first)
    options = options.select_append(foreign_resource.label_column.to_sym) if foreign_resource.label_column
    select_tag "#{resource.table}[#{name}]", options_for_select(options.all.map{|i|[foreign_resource.item_label(i), foreign_resource.primary_key_value(i)]}, item[name]) 
  end

end