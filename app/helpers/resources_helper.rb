module ResourcesHelper

  def header_link key
    params[:order] ||= 'id'
    order, icon = [key, '']
    order, icon = ["#{key} desc", 'icon-chevron-up'] if params[:order] == key
    icon = 'icon-chevron-down' if params[:order] == "#{key} desc"
    res = content_tag('i', '', class: icon, style:"position:absolute")
    style = icon.present? ? "margin-left:20px" : ""
    res << (link_to key.humanize, params.merge(order:order), style:style)
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