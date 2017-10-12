class TableConfiguration < ApplicationRecord
  def candidates_for_polymorphic_associations(generic)
    generic.tables.map do |table|
      column_names = generic.schema(table).map(&:first).map(&:to_s)
      references = column_names.select do |column_name|
        column_name.ends_with?('_type') && column_names.include?(column_name.gsub(/_type$/, '_id'))
      end
      next if references.empty?
      references.map do |column_name|
        reference_name = column_name.gsub(/_type$/, '')
        [table.to_s, reference_name, polymorphic_associations.include?([table.to_s, reference_name])]
      end
    end.compact.flatten(1).sort_by {|table, reference_name, checked| [checked ? 0 : 1, table, reference_name]}
  end

  def polymorphic_associations_as_hashes primary_key
    polymorphic_associations.map do |table, reference_name|
      {table: table.to_sym, foreign_key: "#{reference_name}_id".to_sym, primary_key: primary_key, polymorphic: true}
    end
  end
end
