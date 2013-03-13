class DateTimeInput < SimpleForm::Inputs::DateTimeInput
  def input
    input_html_options[:class] += [:datepicker, :span2]
    value = object[attribute_name]
    value_string = value ? value.to_date.strftime('%m/%d/%Y') : ''
    res = @builder.text_field attribute_name, input_html_options.merge(value: value_string)
    input_html_options[:class].delete :datepicker
    [:year, :month, :day].each_with_index do |type, i|
      v = value ? value.try(type).to_s : ''
      res << (@builder.hidden_field attribute_name, name: "#{@builder.object_name}[#{attribute_name}(#{i+1}i)]", value: v, id: "#{@builder.object_name}_#{attribute_name}_#{i+1}i")
    end
    if input_type == :datetime
      res << (@builder.time_select attribute_name, input_options.merge(ignore_date: true, include_blank: true), input_html_options)
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
