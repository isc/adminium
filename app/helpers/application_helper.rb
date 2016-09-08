module ApplicationHelper
  def flash_class(level)
    case level.to_sym
    when :notice then 'info'
    when :error then 'danger'
    when :alert then 'warning'
    when :success then 'success'
    end
  end

  def foreign_resource resource, key
    resource_for resource.belongs_to_association(key.to_sym)[:referenced_table]
  end

  def display_datetime_control_group opts = {}
    opts[:label] ||= 'DateTime format'
    d = Time.zone.now
    formats = %i(long default short time_ago_in_words)
    datas = formats.map {|f| [display_datetime(d, format: f), f.to_s]}
    datas.unshift [opts[:allow_blank], ''] if opts[:allow_blank]
    content_tag :div, class: 'form-group' do
      content_tag(:label, opts[:label], class: 'control-label col-sm-3') +
        content_tag(:div, class: 'col-sm-9') do
          content_tag(:select, name: opts[:input_name], class: 'form-control') do
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
      column = [f['assoc'].presence, f['column']].compact.map(&:humanize).join(' > ')
      "<strong style=\"white-space: nowrap\">#{column}</strong> #{f['operator']} <i>#{f['operand']}</i>"
    end.join('<br/>')
  end

  def params_without_filter k, filter
    new_params = params.deep_dup
    new_params[filter.to_s].delete k
    new_params[filter.to_s] = new_params[filter.to_s].presence
    new_params.delete 'grouping' if resource.date_column? k.to_sym
    new_params
  end

  def upgrade_to_enterprise_notice
    content_tag :div, class: 'alert alert-warning' do
      "<a class=\"btn btn-warning\" href=\"#{upgrade_account_path plan: 'enterprise'}\">Upgrade</a> to the enterprise plan ($25 per month) and add as many external collaborators as you need to access your data. Moreover, you can assign roles to your collaborators to limit what tables they may access, or prevent them from editing or deleting rows.".html_safe
    end
  end

  def setup_mailto_href account
    res = 'mailto:?'
    res << "subject=#{URI.encode("Need your help setting up Adminium for #{account.name}")}"
    res << "&body=#{URI.encode "Hi there,\n\nCan you please help me setup the Adminium add-on for #{account.name} ? You need to login to Heroku, select the app and click on Adminium in the resources to get to the instructions.\n\nThanks a lot,"}"
  end

  def head_title
    if @full_title
      content_tag :title, @full_title
    else
      content_tag :title, [@title, current_account&.name, 'Adminium'].compact.join(' · ')
    end
  end

  def display_column_default column
    return 'AUTO INCREMENT' if column[:auto_increment]
    return unless column[:default]
    default = column[:ruby_default] || column[:default]
    if default.respond_to?(:constant)
      default.constant
    else
      default == '' ? 'Empty String' : default
    end
  end

  def support_link msg
    '<a href="javascript:void(0)" data-uv-lightbox="classic_widget" data-uv-mode="full" data-uv-primary-color="#cc6d00" data-uv-link-color="#007dbf" data-uv-default-mode="support" data-uv-forum-id="155803">' + msg + '</a>'
  end

  def table_list
    if current_account? && current_account.db_url?
      return @permissions.map {|key, value| key if value['read']}.compact if @permissions
      return @tables if @tables.present?
    end
    []
  end

  def navbar_toggle navbar_id
    content_tag :button, class: 'navbar-toggle collapsed', type: 'button', data: {toggle: 'collapse', target: "##{navbar_id}"}, 'aria-expanded': 'false' do
      content_tag(:span, 'Toggle navigation', class: 'sr-only') +
        (content_tag(:span, nil, class: 'icon-bar') * 3).html_safe
    end
  end

  def icon_button_link path, icon, title, options = {}
    options[:data] ||= {}
    options[:data][:placement] = 'bottom'
    options.merge! rel: 'tooltip', title: title, class: "btn navbar-btn btn-default #{options[:class]}"
    link_to path, options do
      content_tag :i, nil, class: "fa fa-#{icon}"
    end
  end

  def settings_button title
    content_tag :a, class: 'btn navbar-btn btn-default', data: {toggle: 'modal', placement: 'bottom'}, href: '#settings', title: title, rel: 'tooltip' do
      content_tag :i, nil, class: 'fa fa-cog'
    end
  end
end
