module TimeChartBuilder
  
  DEFAULT_GROUPING = %w(Monthly Daily Weekly Yearly Hourly Minutely).map{|g|[g, g.downcase]}
  DEFAULT_GROUPING_PERIODIC = [['Hour of day', 'hour'], ['Day of week', 'dow'], ['Month of year', 'month']]
  DEFAULT_DATE_FORMATS = {'monthly' => '%b', 'weekly' => 'Week %W', 'daily' => '%b %d',
    'yearly' => '%Y', 'hourly' => '%l%P', 'minutely' => '%H:%M'}
  
  def time_chart
    aggregate = time_chart_aggregate params[:column]
    query = clazz.group(aggregate).
      select("#{aggregate} as chart_date, count(#{quoted_table_name}.#{quote_column_name clazz.primary_key})").
      order(aggregate)
    query = query.where(params[:column] => date_range) unless periodic_grouping?
    aggregation clazz.generic.connection.execute(query.to_sql)
    add_missing_zeroes if grouping == 'daily' && @data.present?
    render layout: false
  end
  
  private
  
  def time_chart_aggregate column
    column = "#{quoted_table_name}.#{quote_column_name column}"
    if clazz.generic.postgresql?
      if periodic_grouping?
        "extract(#{grouping} from #{column})"
      else
        aggregate = {'daily' => 'day'}[grouping] || grouping.gsub('ly', '')
        "date_trunc('#{aggregate}', #{column})"
      end
    else
      if periodic_grouping?
        if grouping == 'dow'
          "dayofweek(#{column})"
        else
          "extract(#{grouping} from #{column})"
        end
      else
        case grouping
        when 'yearly'
          "year(#{column})"
        when 'monthly'
          "extract(year_month from #{column})"
        when 'weekly'
          "yearweek(#{column}, 1)"
        when 'daily'
          "date(#{column})"
        when 'hourly'
          "date_format(#{column}, '%Y-%m-%d %H')"
        when 'minutely'
          "date_format(#{column}, '%Y-%m-%d %H:%i')"
        end
      end
    end
  end
  
  def periodic_grouping?
    DEFAULT_GROUPING_PERIODIC.map(&:second).include? grouping
  end
  
  def date_range
    case grouping
    when 'daily'
      start = Date.today - start_date_offset.days
      incomplete_periods? ? start...Date.tomorrow : start...Date.today
    when 'weekly'
      monday = Date.today.beginning_of_week
      start = (monday - start_date_offset.weeks)
      incomplete_periods? ? start...Date.tomorrow : start...monday
    when 'monthly'
      start = (Date.today - start_date_offset.months).beginning_of_month
      incomplete_periods? ? start...Date.tomorrow : start...Date.today.beginning_of_month
    when 'yearly'
      start = start_date_offset.years.ago.beginning_of_year
      incomplete_periods? ? start..Date.tomorrow : start...Date.today.beginning_of_year
    when 'hourly'
      start = start_date_offset.hours.ago.beginning_of_hour
      incomplete_periods? ? start..Time.now : start...Time.now.beginning_of_hour
    when 'minutely'
      start = start_date_offset.minutes.ago.beginning_of_minute
      incomplete_periods? ? start..Time.now : start...Time.now.beginning_of_minute
    end
  end
  
  def aggregation records
    res = records.map do |attributes|
      attributes = Hash[records.fields.zip attributes] unless attributes.is_a? Hash # MySQL / PG discrepancy
      res = [format_date(attributes.delete('chart_date'))]
      attributes.each do |key, value|
        res << value
      end
      res
    end
    @data = res.unshift ['chart_date', records.fields].flatten.uniq unless res.empty?
  end
  
  def format_date date
    return periodic_format date if periodic_grouping?
    if clazz.generic.mysql?
      case grouping
      when 'monthly'
        date = date.to_s
        date = Date.new(date[0..3].to_i, date[4..5].to_i)
      when 'weekly'
        date = date.to_s
        date = Date.commercial(date[0..3].to_i, date[4..5].to_i, 1)
      when 'yearly'
        date = Date.new date
      when 'hourly', 'minutely'
        date = Time.parse date
      end
    else
      date = if %w(hourly minutely).include? grouping
        Time.parse date.to_s
      else
        logger.warn date.to_s
        Date.parse date.to_s
      end
    end
    date.strftime DEFAULT_DATE_FORMATS[grouping]
  end
  
  def periodic_format date
    return date if grouping == 'hour'
    date = date.to_i
    date -= 1 if grouping == 'dow' && clazz.generic.mysql?
    {
      'dow' => I18n.t('date.day_names'),
      'month' => I18n.t('date.month_names')
    }[grouping][date]
  end
  
  def add_missing_zeroes
    num_values = @data[1].size - 1
    date_range.each_with_index do |date, index|
      next if date == date_range.end
      date = date.strftime DEFAULT_DATE_FORMATS[grouping]
      if @data[index + 1].try(:first) != date
        @data.insert(index + 1, [date, [0] * num_values].flatten)
      end
    end
  end
  
  def grouping
    params[:grouping] || 'daily'
  end
  
  def incomplete_periods?
    true
  end
  
  def start_date_offset
    30
  end
  
end
