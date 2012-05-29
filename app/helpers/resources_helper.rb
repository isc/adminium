module ResourcesHelper

  def header_link original_key
    key = original_key
    if key.include? '.'
      parts = key.split('.')
      parts[0] = parts.first.tableize
      key = parts.join('.')
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
      res << link_to(params.merge(order:dorder), title:dtitle, rel:'tooltip') do
        content_tag('i', '', class: "icon-chevron-#{direction} #{active}")
      end
    end
    res << (link_to column_display_name(clazz, original_key), params.merge(order:order), title: title, rel:'tooltip')
  end

  def column_display_name clazz, key
    value = clazz.settings.column_options(key)['rename']
    value.present? ? value : key.humanize

  end

  def page_entries_info(collection, options = {})
    entry_name = options[:entry_name] || (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))
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
        offset + collection.count,
        collection.total_count
      ]
    end
  end

end