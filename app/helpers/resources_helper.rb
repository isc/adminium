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

end