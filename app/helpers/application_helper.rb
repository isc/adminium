module ApplicationHelper

  def flash_class(level)
    case level
    when :notice then 'info'
    when :error then 'error'
    when :alert then 'warning'
    end
  end

  def foreign_resource resource, key
    assoc_info = resource.associations[:belongs_to].values.find {|assoc_info| assoc_info[:foreign_key] == key.to_sym}
    resource_for(assoc_info[:referenced_table])
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
    content_tag :div, id: 'bowlG' do
      content_tag :div, id: 'bowl_ringG' do
        content_tag :div, class: 'ball_holderG' do
          content_tag :div, class: 'ballG' do
          end
        end
      end
    end
  end

  def format_param_for_removal k, v
    "#{CGI.escape("where[#{k}]")}=#{CGI.escape(v)}"
  end

  def upgrade_to_enterprise_notice account
    content_tag :div, class: 'alert notice' do
      "<a class=\"btn btn-warning\" href=\"#{upgrade_account_path(plan:'enterprise')}\">Upgrade</a> to the enterprise plan ($25 per month) and add as many external collaborators as you need to access your data. Moreover, you can assign roles to your collaborators to limit what tables they may access, or prevent them from editing or deleting rows.".html_safe
    end
  end

  def setup_mailto_href account
    res = 'mailto:?'
    res << "subject=#{URI::encode("Need your help setting up Adminium for #{account.name}")}"
    res << "&body=#{URI::encode "Hi there,\n\nCan you please help me setup the Adminium add-on for #{account.name} ? You need to login to Heroku, select the app and click on Adminium in the resources to get to the instructions.\n\nThanks a lot,"}"
  end

  def head_title
    if @full_title
      content_tag :title, @full_title
    else
      content_tag :title, [@title, current_account.try(:name), 'Adminium'].compact.join(' | ')
    end
  end
  
  def display_column_default column
    return unless column[:default]
    default = column[:ruby_default] || column[:default]
    default = default.respond_to?(:constant) ? default.constant : (default == '' ? 'Empty String' : default)
  end
  
  def support_link msg
    '<a href="javascript:void(0)" data-uv-lightbox="classic_widget" data-uv-mode="full" data-uv-primary-color="#cc6d00" data-uv-link-color="#007dbf" data-uv-default-mode="support" data-uv-forum-id="155803">'+msg+'</a>'
  end
  
  def table_list
   if current_account? && current_account.db_url.present?
    return @permissions.map {|key, value| key if value['read']}.compact if @permissions
    return @tables if @tables.present?
   end
   return []
  end
  
  def zopim_tags
    return 'visitor'.to_json unless current_account
    [current_account.name, current_account.plan, "Tables:#{current_account.tables_count}", "Adapter:#{current_account.adapter}"].map(&:to_json).join(',')
  end
  
end
