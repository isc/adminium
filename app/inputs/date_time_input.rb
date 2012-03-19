class DateTimeInput < SimpleForm::Inputs::DateTimeInput
  def input
    input_html_options[:class] += [:datepicker, :span2]
    value = object[attribute_name] || Date.today
    value = value.to_date.strftime '%m/%d/%Y'
    res = @builder.text_field attribute_name, input_html_options.merge(value: value)
    input_html_options[:class].delete :datepicker
    res << (@builder.time_select attribute_name, input_options, input_html_options) if input_type == :datetime
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
