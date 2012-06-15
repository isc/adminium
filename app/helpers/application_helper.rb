module ApplicationHelper

  def flash_class(level)
    case level
    when :notice then 'info'
    when :error then 'error'
    when :alert then 'warning'
    end
  end

  # FIXME n+1 queries perf issue with label_column option

  def foreign_class clazz, key
    assoc_name = key.gsub /_id$/, ''
    reflection = clazz.reflections[assoc_name.to_sym]
    @generic.table(assoc_name.classify.tableize)
  end

  def foreign_class_and_path item, key, value
    assoc_name = key.gsub /_id$/, ''
    reflection = item.class.reflections[assoc_name.to_sym]
    if reflection.options[:polymorphic]
      assoc_type = item.send key.gsub(/_id/, '_type')
      class_name, path = assoc_type, resource_path(assoc_type.to_s.tableize, value)
    else
      class_name, path = assoc_name.classify, resource_path(reflection.table_name, value)
    end
    foreign_clazz = @generic.table(class_name.tableize)
    [class_name, foreign_clazz, path]
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
    content_tag :div, :id => 'bowlG' do
      content_tag :div, :id =>'bowl_ringG' do
        content_tag :div, :class => 'ball_holderG' do
          content_tag :div, :class => 'ballG' do
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
      "<a class=\"btn btn-warning\" href=\"#{account.upgrade_link}\">Upgrade</a> to the enterprise plan ($50 per month) and add as many collaborators you need to access your data. Moreover, you can define roles to each collaborators to limit what tables they may access, or prevent them from editing or deleting rows.".html_safe
    end
  end

end
