class Generic::Base < ActiveRecord::Base
  cattr_accessor :adminium_account_id, :generic
  extend Settings

  def self.abstract_class?
    true
  end
  def self.original_name
    name.demodulize
  end
  def self.inheritance_column
  end

  def self.foreign_key? column_name
    reflections.values.find {|reflection| reflection.macro == :belongs_to && reflection.foreign_key == column_name }
  end

  def adminium_label
    if (label_column = self.class.settings.label_column)
      label = self[label_column]
    end
    label || "#{self.class.original_name.humanize} ##{self[self.class.primary_key]}"
  end

  # workaround to allow column names like save, changes.
  # can't edit those columns though
  def self.instance_method_already_implemented?(method)
    super
  rescue ActiveRecord::DangerousAttributeError
    true
  end
end
