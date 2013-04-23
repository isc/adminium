module Import

  def import
    @title = 'Import'
  end

  def perform_import
    data = JSON.parse(params[:data])
    columns = data['headers']
    pkey = resource.primary_key.to_s
    columns_without_pk = columns.clone
    columns_without_pk.delete pkey
    import_rows = data['create'].present? ? data['create'] : nil
    update_rows = data['update'].present? ? data['update'] : nil
    fromId = toId = 0
    updated_ids = []
    begin
      if import_rows
        fromId = resource.query.select(resource.primary_key).order(:id).last.try(:[], resource.primary_key) || 0
        res = resource.query.import(columns_without_pk, import_rows)
        toId = resource.query.select(resource.primary_key).order(:id).last.try(:[], resource.primary_key) || 0
      end
      if update_rows
        updated_ids = update_from_import(pkey, columns, update_rows)
      end
    rescue => error
      render json: {error: error.to_s}.to_json
      return
    end
    if (import_rows && fromId == toId)
      render json: {error: "No new record were imported (#{fromId} -> #{toId})"}.to_json
      return
    end
    if (update_rows && updated_ids.blank?)
      render json: {error: "No records were updated"}.to_json
      return
    end
    set_last_import_filter(import_rows, update_rows, fromId, toId, updated_ids)
    result = {success: true}
    render json: result.to_json
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
    resource.filters['last_import'] =  import_filter
    resource.save
  end

  def check_existence
     ids = params[:id].uniq
     primary_key = resource.primary_key
     found_items_ids = resource.query.where(primary_key => ids).select(primary_key).map{|r|r[primary_key].to_s}.uniq
     not_found_ids = ids.map(&:to_s) - found_items_ids
     result = if not_found_ids.present?
       {error: true, ids: not_found_ids}
     else
       {success: true}
     end
     render json: result
  end
  
end
