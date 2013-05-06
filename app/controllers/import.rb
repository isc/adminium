module Import

  def import
    @title = 'Import'
  end

  def perform_import
    data = JSON.parse params[:data]
    columns = data['headers']
    pkey = resource.primary_key.to_s
    columns_for_import = columns.clone
    import_rows, update_rows = data['create'].presence, data['update'].presence
    columns_for_import.delete pkey if import_rows && columns_for_import.size > import_rows.first.size
    fromId = toId = 0
    updated_ids = []
    begin
      if import_rows
        fromId = resource.last_primary_key_value
        resource.query.import columns_for_import, import_rows
        toId = resource.last_primary_key_value
      end
      updated_ids = update_from_import pkey, columns, update_rows if update_rows
    rescue => error
      render json: {error: error.to_s} and return
    end
    if import_rows && fromId == toId
      render json: {error: "No new record was imported (#{fromId} -> #{toId})"} and return
    end
    if update_rows && updated_ids.blank?
      render json: {error: 'No records were updated'} and return
    end
    set_last_import_filter import_rows, update_rows, fromId, toId, updated_ids
    render json: {success: true}
  end

  def set_last_import_filter import_rows, update_rows, fromId, toId, updated_ids
    pkey = resource.primary_key.to_s
    import_filter = []
    if import_rows && update_rows
      created_ids = resource.query.where(resource.primary_key => (fromId+1)..toId).group_and_count(resource.primary_key).map{|r|r[resource.primary_key]}
      updated_ids += created_ids
      import_filter.push "column" => pkey, "type"=>"integer", "operator"=>"IN", "operand" => updated_ids.join(',')
    else
      if import_rows
        import_filter.push "column" => pkey, "type" => "integer", "operator"=>">", "operand" => fromId
        import_filter.push "column" => pkey, "type" => "integer", "operator"=>"<=", "operand" => toId
      end
      if update_rows
        import_filter.push "column" => pkey, "type"=>"integer", "operator"=>"IN", "operand" => updated_ids.join(',')
      end
    end
    resource.filters['Last import'] = import_filter
    resource.save
  end

  def check_existence
     ids = params[:id].uniq
     primary_key = resource.primary_key
     found_items_ids = resource.query.where(primary_key => ids).select(primary_key).map{|r|r[primary_key].to_s}.uniq
     not_found_ids = ids.map(&:to_s) - found_items_ids
     result = if not_found_ids.present? && not_found_ids.size < ids.size
       {error: true, ids: not_found_ids}
     else
       {success: true, update: (not_found_ids.empty?)}
     end
     render json: result
  end
  
  private
  
  def update_from_import pk, columns, data
    data.map do |row|
      attrs = {}
      columns.each_with_index do |name, index|
        attrs[name] = row[index]
      end
      id = attrs.delete pk
      resource.update_item id, attrs
      id
    end
  end

end
