module EvolutionChartBuilder
  def evolution_chart
    column = qualify params[:table], params[:column]
    label_column = {'pg_stat_statements' => :query, 'pg_stat_all_indexes' => :indexrelname}
    @items = resource.query
    dataset_filtering
    @data = @items.select(column, label_column).all.map {|row| [row[label_column], row[params[:column].to_sym]]}.to_h
    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @data }
    end
  end
end
