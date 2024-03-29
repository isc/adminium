module StatChartBuilder
  include ResourcesHelper
  include ActionView::Helpers::NumberHelper

  def stat_chart
    column = qualify params[:table], params[:column]
    @items = resource.query
    dataset_filtering
    @items_for_stats = @items
    @items = @items.select(Sequel.as(Sequel.function(:count, Sequel.function(:distinct, column)), 'distinct'))
    %i(max min avg sum count).each do |calculation|
      clause = Sequel.as(Sequel.function(calculation, column), calculation)
      @items = @items.select_append(clause)
    end
    @data_hash = @items.all.first
    count = @data_hash[:count]
    if count.positive?
      value = @items_for_stats.order(column).limit(1, count / 2).select(column).first
      @data_hash[:median] = value[params[:column].to_sym]
    end
    @data = []
    %i(max avg median min sum count distinct).each do |calc|
      value = @data_hash[calc]
      unless %i(count distinct).include?(calc)
        value = value.round(2) if [Float, BigDecimal].include?(value.class)
        value = display_number(params[:column].to_sym, nil, resource, value) if value
      end
      d = [I18n.t("statistics.#{calc}"), value]
      d.push(@data_hash[calc]) if %i[max min].include?(calc)
      @data.push d
    end
    respond_to do |format|
      format.html do
        @widget = current_account.stat_chart_widgets.where(table: params[:table], columns: params[:column]).first
        render layout: false
      end
      format.json do
        render json: {
          chart_data: @data,
          chart_type: 'StatChart',
          grouping: 'none',
          column: params[:column],
          id: params[:widget_id]
        }
      end
    end
  end
end
