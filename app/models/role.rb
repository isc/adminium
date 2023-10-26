class Role < ApplicationRecord
  validates :name, presence: true
  belongs_to :account
  has_and_belongs_to_many :collaborators
  serialize :permissions, coder: JSON
  before_save :normalize_permissions

  def to_s
    name
  end

  def normalize_permissions
    self.permissions = (permissions || {}).to_h
  end
end
