module PieChartBuilder
  private

  def pie_chart
    @items = resource.query
    if params[:column]['.']
      foreign_key, column_name = params[:column].split('.')
      column = qualify(join_belongs_to(foreign_key), column_name.to_sym)
      table_name = resource.belongs_to_association(foreign_key.to_sym)[:referenced_table]
    else
      column_name = params[:column]
      table_name = params[:table]
      column = qualify params[:table], params[:column]
    end
    dataset_filtering
    @data = @items.group_and_count(column).reverse_order(:count).limit(100).to_a
    enum = determine_enum table_name, column_name
    @data.map! do |row|
      key, count = row.values
      v = enum[key] || enum[key.to_s] || {'label' => key.to_s, 'color' => new_color}
      [v['label'], count, key && key.to_s, v['color'] || new_color]
    end

    respond_to do |format|
      format.html do
        @widget = current_account.pie_chart_widgets.find_by table: params[:table], columns: params[:column]
        render layout: false
      end
      format.json do
        render json: {chart_data: @data, chart_type: 'PieChart', grouping: 'none',
                      column: params[:column], id: params[:widget_id]}
      end
    end
  end

  def new_color
    @i ||= 0
    @i += 1
    %w(#CCC #AAA)[@i % 2]
  end

  def determine_enum(table_name, name)
    resource = resource_for table_name
    name = name.to_sym
    enum =
      if resource.boolean_column? name
        options = resource.column_options(name)
        {true => {'color' => '#07be25', 'label' => options['boolean_true'] || 'True'},
         false => {'color' => '#777', 'label' => options['boolean_false'] || 'False'}}
      elsif (assoc = resource.belongs_to_association(name))
        referenced_resource = resource_for assoc[:referenced_table] if assoc[:referenced_table]
        if referenced_resource&.label_column && user_can?('show', assoc[:referenced_table])
          values = @data.map {|row| row[assoc[:foreign_key]]}
          referenced_resource.query.where(assoc[:primary_key] => values)
            .select(assoc[:primary_key], Sequel.identifier(referenced_resource.label_column)).to_a
            .map do |h|
              [h[assoc[:primary_key]], {'color' => new_color, 'label' => h[referenced_resource.label_column.to_sym]}]
            end.to_h
        else
          {}
        end
      else
        resource.enum_values_for(name) || {}
      end
    enum[nil] = {'color' => '#DDD', 'label' => 'Not set'}
    enum
  end

  def pie_chart_column?(name)
    return true if resource.pie_chart_column?(name)
    return false unless name['.']
    foreign_key, column = name.to_s.split('.')
    table = resource.belongs_to_association(foreign_key.to_sym)[:referenced_table]
    resource_for(table).pie_chart_column?(column)
  end
end
