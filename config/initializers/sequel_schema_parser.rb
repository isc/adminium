module Sequel
  module Postgres
    module DatabaseMethods
      def schema_parse_complete(opts=OPTS) # modification
        m = output_identifier_meth(opts[:dataset])
        # oid = regclass_oid(table_name, opts)
        ds = metadata_dataset.select{[
            pg_class[:relname], # addition
            pg_attribute[:attname].as(:name),
            SQL::Cast.new(pg_attribute[:atttypid], :integer).as(:oid),
            SQL::Cast.new(basetype[:oid], :integer).as(:base_oid),
            SQL::Function.new(:format_type, basetype[:oid], pg_type[:typtypmod]).as(:db_base_type),
            SQL::Function.new(:format_type, pg_type[:oid], pg_attribute[:atttypmod]).as(:db_type),
            SQL::Function.new(:pg_get_expr, pg_attrdef[:adbin], pg_class[:oid]).as(:default),
            SQL::BooleanExpression.new(:NOT, pg_attribute[:attnotnull]).as(:allow_null),
            SQL::Function.new(:COALESCE, SQL::BooleanExpression.from_value_pairs(pg_attribute[:attnum] => SQL::Function.new(:ANY, pg_index[:indkey])), false).as(:primary_key)]}.
          from(:pg_class).
          join(:pg_attribute, :attrelid=>:oid).
          join(:pg_type, :oid=>:atttypid).
          left_outer_join(Sequel[:pg_type].as(:basetype), :oid=>:typbasetype).
          left_outer_join(:pg_attrdef, :adrelid=>Sequel[:pg_class][:oid], :adnum=>Sequel[:pg_attribute][:attnum]).
          left_outer_join(:pg_index, :indrelid=>Sequel[:pg_class][:oid], :indisprimary=>true).
          join(:pg_namespace, :oid=>Sequel[:pg_class][:relnamespace]). # addition
          where{{pg_attribute[:attisdropped]=>false}}.
          filter(:relkind=>['v', 'r']). # addition
          where{pg_attribute[:attnum] > 0}.
          # where{{pg_class[:oid]=>oid}}.
          order{pg_attribute[:attnum]}

        if server_version > 100000
          ds = ds.select_append{pg_attribute[:attidentity]}
        end
        ds = filter_schema ds, opts # addition
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
          identity = row.delete(:attidentity)
          if row[:primary_key]
            row[:auto_increment] = !!(row[:default] =~ /\A(?:nextval)/i) || identity == 'a' || identity == 'd'
          end
          [m.call(row.delete(:name)), row]
        end.group_by {|name, row| "\"#{row.delete(:relname)}\""} # addition
      end
    end
  end
end
