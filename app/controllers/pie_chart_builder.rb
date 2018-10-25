module PieChartBuilder
  private

  def pie_chart
    column = qualify params[:table], params[:column]
    @items = resource.query
    dataset_filtering
    @data = @items.group_and_count(column).reverse_order(:count).limit(100).to_a
    enum = determine_enum
    @data.map! do |row|
      key, count = row.values
      v = enum[key] || enum[key.to_s] || {'label' => key, 'color' => new_color}
      [v['label'], count, key, v['color'] || new_color]
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

  def determine_enum
    name = params[:column].to_sym
    enum =
      if resource.boolean_column? name
        options = resource.column_options(name)
        {true => {'color' => '#07be25', 'label' => options['boolean_true'] || 'True'},
         false => {'color' => '#777', 'label' => options['boolean_false'] || 'False'}}
      elsif (assoc = resource.belongs_to_association(name))
        referenced_resource = resource_for assoc[:referenced_table] if assoc[:referenced_table]
        if referenced_resource&.label_column
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
        resource.enum_values_for(params[:column]) || {}
      end
    enum[nil] = {'color' => '#DDD', 'label' => 'Not set'}
    enum
  end
end
