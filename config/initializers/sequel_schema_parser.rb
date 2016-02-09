module Sequel
  module Postgres
    module DatabaseMethods
      def schema_parse_complete opts=OPTS # modification
        m = output_identifier_meth(opts[:dataset])
        ds = metadata_dataset.select(:pg_attribute__attname___name,
            :pg_class__relname, # addition
            SQL::Cast.new(:pg_attribute__atttypid, :integer).as(:oid),
            SQL::Cast.new(:basetype__oid, :integer).as(:base_oid),
            SQL::Function.new(:format_type, :basetype__oid, :pg_type__typtypmod).as(:db_base_type),
            SQL::Function.new(:format_type, :pg_type__oid, :pg_attribute__atttypmod).as(:db_type),
            SQL::Function.new(:pg_get_expr, :pg_attrdef__adbin, :pg_class__oid).as(:default),
            SQL::BooleanExpression.new(:NOT, :pg_attribute__attnotnull).as(:allow_null),
            SQL::Function.new(:COALESCE, SQL::BooleanExpression.from_value_pairs(:pg_attribute__attnum => SQL::Function.new(:ANY, :pg_index__indkey)), false).as(:primary_key)).
          from(:pg_class).
          join(:pg_attribute, :attrelid=>:oid).
          join(:pg_type, :oid=>:atttypid).
          left_outer_join(:pg_type___basetype, :oid=>:typbasetype).
          left_outer_join(:pg_attrdef, :adrelid=>:pg_class__oid, :adnum=>:pg_attribute__attnum).
          left_outer_join(:pg_index, :indrelid=>:pg_class__oid, :indisprimary=>true).
          join(:pg_namespace, :oid=>:pg_class__relnamespace). # addition
          filter(:pg_attribute__attisdropped=>false).
          filter(:relkind=>['v', 'r']). #addition
          filter{|o| o.pg_attribute__attnum > 0}.
          # filter(:pg_class__oid=>regclass_oid(table_name, opts)).
          order(:pg_attribute__attnum)
        ds = filter_schema ds, opts
        @schemas = ds.map do |row| # modification
          row[:default] = nil if blank_object?(row[:default])
          if row[:base_oid]
            row[:domain_oid] = row[:oid]
            row[:oid] = row.delete(:base_oid)
            row[:db_domain_type] = row[:db_type]
            row[:db_type] = row.delete(:db_base_type)
          else
            row.delete(:base_oid)
            row.delete(:db_base_type)
          end
          row[:type] = schema_column_type(row[:db_type])
          row[:ruby_default] = column_schema_to_ruby_default(row[:default], row[:type])
          if row[:primary_key]
            row[:auto_increment] = !!(row[:default] =~ /\Anextval/io)
          end
          [m.call(row.delete(:name)), row]
        end.group_by {|name, row| "\"#{row.delete(:relname)}\""} # addition
        # schema_utility_dataset.literal row.delete(:relname)
      end
    end
  end
end
