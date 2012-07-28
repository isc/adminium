module ActiveRecord
  module ConnectionAdapters
    class SchemaCache
      attr_reader :columns, :columns_hash, :primary_keys, :tables
      attr_reader :connection

      def initialize(conn)
        @connection = conn
        @tables     = {}

        @columns = Hash.new do |h, table_name|
          h[table_name] = conn.columns(table_name, "#{table_name} Columns")
        end

        @columns_hash = Hash.new do |h, table_name|
          h[table_name] = Hash[columns[table_name].map { |col|
            [col.name, col]
          }]
        end

        @primary_keys = Hash.new do |h, table_name|
          table_name = conn.adapter_name == 'PostgreSQL' ? conn.quote_table_name(table_name) : table_name
          h[table_name] = table_exists?(table_name) ? conn.primary_key(table_name) : nil
        end
      end
    end
  end
end