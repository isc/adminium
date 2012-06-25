require 'csv' # adds a .to_csv method to Array instances

class Array

  def to_my_csv(options = {})
    clazz = first.class
    keys = clazz.settings.columns[:export]
    options = {col_sep: clazz.settings.export_col_sep}
    out = if clazz.settings.export_skip_header
      ''
    else
      keys.map { |k| clazz.column_display_name k }.to_csv(options)
    end
    self.each do |item|
      out << keys.map do |key|
        if key.include? "."
          parts = key.split('.')
          pitem = item.send(parts.first)
          pitem[parts.second] if pitem
        elsif key.starts_with? 'has_many/'
          key = key.gsub 'has_many/', ''
          foreign_key_name = item.class.original_name.underscore + '_id'
          foreign_key_value = item[item.class.primary_key]
          item.class.generic.table(key).where(foreign_key_name => foreign_key_value).count
        else
          item[key]
        end
      end.to_csv(options)
    end
    out
  end
end

ActionController::Renderers.add :csv do |csv, options|
  csv = csv.respond_to?(:to_my_csv) ? csv.to_my_csv() : csv
  self.content_type ||= Mime::CSV
  self.response_body = csv
end