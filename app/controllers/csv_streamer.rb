class CsvStreamer

  attr_reader :resource, :other_resources

  def initialize items, associated_items, resource, other_resources
    @items, @associated_items = items, associated_items
    @resource, @other_resources = resource, other_resources
    @associated_items.each do |k, v| # sort items for binary search
      @associated_items[k] = v.sort {|e| e[other_resources[k].primary_key]}
    end
  end

  def each
    keys = resource.columns[:export]
    yield keys.map{|k|resource.column_display_name k}.to_csv(col_sep: resource.export_col_sep) unless resource.export_skip_header
    @items.each {|item| yield csv_row(item, keys)}
  end

  def csv_row item, keys
    keys.map do |key|
      if key.to_s.include? '.'
        referenced_table, column = key.to_s.split('.').map(&:to_sym)
        assoc = resource.associations[:belongs_to][referenced_table]
        pitem = @associated_items[referenced_table].binary_search {|i| i[assoc[:primary_key]] <=> item[assoc[:foreign_key]]} if item[assoc[:foreign_key]]
        other_resources[referenced_table].raw_column_output pitem, column if pitem
      else
        resource.raw_column_output item, key
      end
    end.to_csv(col_sep: resource.export_col_sep)
  end

end
