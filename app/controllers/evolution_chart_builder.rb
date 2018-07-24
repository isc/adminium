module EvolutionChartBuilder
  def evolution_chart
    column = qualify params[:table], params[:column]
    @items = resource.query
    dataset_filtering
    @data = @items.select(column, :indexrelname).all.map {|row| [row[:indexrelname], row[params[:column].to_sym]]}.to_h
    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: @data }
    end
  end
end
