module Import
  def import
    @title = 'Import'
  end

  def perform_import
    data = JSON.parse params[:data]

    pkey = resource.primary_key.to_s
    insert_rows, update_rows = data['create'].presence, data['update'].presence
    insert_columns, update_columns = magic_timestamps insert_rows, update_rows, data['headers']
    insert_columns.delete pkey if insert_rows && insert_columns.size > insert_rows.first.size
    from_id = to_id = 0
    updated_ids = []
    begin
      if insert_rows
        from_id = resource.last_primary_key_value
        resource.query.import insert_columns, insert_rows
        to_id = resource.last_primary_key_value
      end
      updated_ids = update_from_import pkey, update_columns, update_rows if update_rows
    rescue => error
      return render json: {error: error.to_s}
    end
    if insert_rows && from_id == to_id
      return render json: {error: "No new record was imported (#{from_id} -> #{to_id})"}
    end
    if update_rows && updated_ids.blank?
      return render json: {error: 'No records were updated'}
    end
    set_last_import_filter insert_rows, update_rows, from_id, to_id, updated_ids
    render json: {success: true}
  end

  def set_last_import_filter insert_rows, update_rows, from_id, to_id, updated_ids
    pkey = resource.primary_key.to_s
    import_filter = []
    if insert_rows && update_rows
      created_ids = resource.query.where(resource.primary_key => (from_id + 1)..to_id).group_and_count(resource.primary_key).map {|r| r[resource.primary_key]}
      updated_ids += created_ids
      import_filter.push 'column' => pkey, 'type' => 'integer', 'operator' => 'IN', 'operand' => updated_ids.join(',')
    else
      if insert_rows
        import_filter.push 'column' => pkey, 'type' => 'integer', 'operator' => '>', 'operand' => from_id
        import_filter.push 'column' => pkey, 'type' => 'integer', 'operator' => '<=', 'operand' => to_id
      end
      if update_rows
        import_filter.push 'column' => pkey, 'type' => 'integer', 'operator' => 'IN', 'operand' => updated_ids.join(',')
      end
    end
    current_account.searches.create! name: 'Last import', table: resource.table, conditions: import_filter
  end

  def check_existence
    ids = params[:id].uniq
    primary_key = resource.primary_key
    found_items_ids = resource.query.where(primary_key => ids).select(primary_key).map {|r| r[primary_key].to_s}.uniq
    not_found_ids = ids.map(&:to_s) - found_items_ids
    result = if not_found_ids.present? && not_found_ids.size < ids.size
               {error: true, ids: not_found_ids}
             else
               {success: true, update: not_found_ids.empty?}
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

  def magic_timestamps insert_rows, update_rows, columns
    now, insert_columns, update_columns = application_time_zone.now.to_datetime, columns.clone, columns.clone
    %i(updated_at updated_on created_at created_on inserted_at).each do |column|
      next if columns.include? column.to_s
      next unless resource.column_names.include? column
      unless insert_rows.nil?
        insert_rows.each {|row| row << now}
        insert_columns << column
      end
      unless update_rows.nil? || (column.to_s[/(created)|(inserted)/])
        update_rows.each {|row| row << now}
        update_columns << column
      end
    end
    [insert_columns, update_columns]
  end
end
