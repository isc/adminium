module PieChartBuilder
  private

  def pie_chart
    column = qualify params[:table], params[:column]
    name = params[:column].to_sym
    @items = resource.query
    apply_where
    apply_filters
    apply_search
    enum = if resource.boolean_column? name
             options = resource.column_options(name)
             {
               true => {'color' => '#07be25', 'label' => options['boolean_true'] || 'True'},
               false => {'color' => '#777', 'label' => options['boolean_false'] || 'False'}
             }
           elsif resource.foreign_key? name
             {}
           else
             resource.enum_values_for(params[:column]) || {}
           end
    enum[nil] = {'color' => '#DDD', 'label' => 'not set'}
    @data = @items.group_and_count(column).reverse_order(:count).limit(100).map do |row|
      key, count = row.values
      v = enum[key] || {'label' => key, 'color' => new_color}
      [v['label'], count, key, v['color']]
    end

    respond_to do |format|
      format.html do
        @widget = current_account.pie_chart_widgets.where(table: params[:table], columns: params[:column]).first
        render layout: false
      end
      format.json do
        render json: {
          chart_data: @data,
          chart_type: 'PieChart',
          grouping: 'none',
          column: params[:column],
          id: params[:widget_id]
        }
      end
    end
  end

  def new_color
    @i ||= 0
    @i += 1
    ['#CCC', '#AAA'][@i % 2]
  end

  def sum_case_when c, x
    Sequel.as(Sequel.function(:sum, Sequel.case({{qualify(resource.table, c) => x} => 1}, 0)), "c#{rand(1000)}")
  end

  def apply_enum_statistics
    resource.schema_hash.each do |name, _|
      enum_values = resource.enum_values_for(name)
      next if enum_values.blank?
      enum_values.each do |key, value|
        @projections.push sum_case_when(name, key)
        @select_values.push [name, value]
      end
    end
  end
end
