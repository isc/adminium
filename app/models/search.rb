class Search < ApplicationRecord
  belongs_to :account
  validates :name, :table, presence: true
  validate :conditions_operands, on: %i(create update)

  attr_accessor :generic

  private

  def conditions_operands
    resource = Resource.new generic, table
    conditions.each do |condition|
      validate_integer_array_condition condition, resource
      validate_jsonb_containment_condition condition
    end
  end

  def validate_integer_array_condition condition, resource
    return unless condition['operator'] == 'IN'
    type = resource.column_type condition['column'].to_sym
    return unless type == :integer
    condition['operand'].split(',').each do |value|
      errors.add(:base, "#{value} is not an integer") unless value.strip =~ /\A\d+\z/
    end
  end

  def validate_jsonb_containment_condition condition
    return unless condition['type'] == 'jsonb' && condition['operator'] == 'contains'
    begin
      JSON.parse(condition['operand'])
    rescue JSON::ParserError
      errors.add :base, "#{condition['operand']} cannot be parsed as JSON"
    end
  end
end
