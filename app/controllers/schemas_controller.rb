class SchemasController < ApplicationController
  before_action :require_admin, except: :show
  before_action :check_permissions, only: :show

  def show
    @title = 'Schema'
    params[:table] = params[:id]
    @resource = resource_for params[:table]
    @readonly = @resource.system_table? || !admin?
    @comments = @generic.column_comments params[:table]
    @table_comment = @generic.table_comments([params[:table]]).first
    @comments.delete @table_comment
    @indexes = @generic.detailed_indexes params[:table]
  end

  def new; end

  def update
    return rename_table if params[:table_name]
    return remove_column if params[:remove_column]
    return rename_column if params[:new_column_name]
    return add_column if params[:add_column]
    return change_column_type if params[:new_column_type]
    truncate if params[:truncate]
  end

  def create
    table_name = Sequel.identifier params[:table_name]
    columns, primary_column_names = reformat_columns_params
    @generic.db.create_table table_name do
      columns.each do |data|
        if primary_column_names == [data[:name]]
          primary_key data[:name], data[:ruby_type]
        else
          column data[:name], data[:ruby_type], data[:options]
        end
      end
      primary_key(primary_column_names, name: "#{table_name}_pk") if primary_column_names.many?
    end
    render json: {table_name: params[:table_name]}
  rescue Sequel::Error => e
    render json: {error: e.message}
  end

  def destroy
    if params[:id] == params[:table_name_confirmation]
      @generic.db.drop_table params[:id]
    else
      flash[:error] = 'Destroying the table failed: the table name confirmation mismatched.'
    end
  rescue Sequel::Error => e
    flash[:error] = "Destroying the table failed: #{e.message}"
  ensure
    redirect_to dashboard_path, flash: {success: "Table #{params[:id]} has been dropped."}
  end

  private

  def rename_table
    @generic.db.rename_table Sequel.identifier(params[:id]), Sequel.identifier(params[:table_name])
    redirect_to schema_path(params[:table_name]), flash: {success: "Table #{params[:id]} has been renamed to #{params[:table_name]}."}
  rescue Sequel::Error => e
    flash[:error] = "Renaming the table failed: #{e.message}"
    redirect_to schema_path(params[:id])
  end

  def remove_column
    column_name = params[:remove_column]
    @generic.db.alter_table(params[:id].to_sym) {drop_column column_name}
  rescue Sequel::Error => e
    flash[:error] = "Dropping column #{column_name} failed: #{e.message}"
  ensure
    redirect_to schema_path(params[:id])
  end

  def rename_column
    original_column_name = params[:column_name].to_sym
    new_column_name = params[:new_column_name].to_sym
    @generic.db.alter_table(params[:id].to_sym) {rename_column original_column_name, new_column_name}
  rescue Sequel::Error => e
    flash[:error] = "Renaming column #{original_column_name} failed: #{e.message}"
  ensure
    redirect_to schema_path(params[:id])
  end

  def add_column
    table_name = params[:id]
    columns, = reformat_columns_params
    @generic.db.alter_table table_name do
      columns.each do |data|
        add_column data[:name], data[:ruby_type], data[:options]
      end
    end
  rescue Sequel::Error => e
    flash[:error] = "Adding column failed: #{e.message}"
  ensure
    redirect_to schema_path(params[:id])
  end

  def truncate
    if params[:id] == params[:table_name_confirmation]
      @generic.db[Sequel.identifier params[:id]].truncate restart: params[:restart].present?
    else
      flash[:error] = 'Truncating the table failed: the table name confirmation mismatched.'
    end
  rescue Sequel::Error => e
    flash[:error] = "Truncating the table failed: #{e.message}"
  ensure
    flash[:success] = "Table #{params[:id]} has been truncated." unless flash[:error]
    redirect_to dashboard_path
  end

  def reformat_columns_params
    primary_column_names = []
    columns = params[:columns].map do |column|
      next if column[:name].blank?
      c = {}
      type, options = type_converted column[:type]
      c[:ruby_type] = type
      c[:name] = column[:name].to_sym
      primary_column_names.push c[:name] if column[:primary]
      column[:default] = nil if column[:default].blank? || column[:default] == 'NULL'
      c[:options] = {null: column[:null].present?, unique: column[:unique].present?}
      c[:options][:default] = column[:default] if column[:default].present?
      c[:options].merge! options if options
      c
    end.compact
    [columns, primary_column_names]
  end

  def change_column_type
    table = params[:id].to_sym
    column = params[:column_name].to_sym
    type, options = type_converted(params[:new_column_type])
    options ||= {}
    @generic.db.set_column_type table, column, type, options
  rescue Sequel::Error => e
    flash[:error] = "Changing column #{column}'s type failed: #{e.message}"
  ensure
    redirect_to schema_path(params[:id])
  end

  def type_converted type
    case type.to_sym
    when :integer
      Integer
    when :boolean
      TrueClass
    when :string
      [String, size: 255]
    when :text
      [String, text: true]
    when :float
      Float
    when :decimal
      BigDecimal
    when :datetime
      DateTime
    when :date
      Date
    when :blob
      File
    when :time
      [Time, only_time: true]
    end
  end
end
