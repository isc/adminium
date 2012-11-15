class DateTimeInput < SimpleForm::Inputs::DateTimeInput
  def input
    input_html_options[:class] += [:datepicker, :span2]
    value = object[attribute_name]
    value = value.to_date.strftime '%m/%d/%Y' if value
    res = @builder.text_field attribute_name, input_html_options.merge(value: value)
    input_html_options[:class].delete :datepicker
    input_options[:prompt] = {hour: '', minute: '', second: ''}
    if input_type == :datetime
      res << (@builder.time_select attribute_name, input_options, input_html_options)
    else
      res << (@builder.date_select attribute_name, input_options, input_html_options.merge(style: 'display:none'))
    end
    res
  end

  def has_required?
    false
  end

  private

  def label_target
    attribute_name
  end
end
