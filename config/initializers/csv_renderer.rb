require 'csv' # adds a .to_csv method to Array instances

class Array

  def to_my_csv(options = Hash.new)
    clazz = first.class
    keys = clazz.settings.columns[:listing]
    out = keys.map do |key|
      key.humanize
    end.to_csv(options)
    self.each do |item|
      out << keys.map do |key|
        item[key]
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