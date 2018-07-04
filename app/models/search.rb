class Search < ApplicationRecord
  belongs_to :account
  validates :name, :table, presence: true
  validate :conditions_operands

  attr_accessor :generic

  def conditions_operands
    resource = Resource::Base.new @generic, table
    conditions.each do |condition|
      next unless condition['operator'] == 'IN'
      type = resource.column_type condition['column'].to_sym
      next unless type == :integer
      condition['operand'].split(',').each do |value|
        errors.add(:base, "#{value} is not an integer") unless value.strip =~ /\A\d+\z/
      end
    end
  end
end
