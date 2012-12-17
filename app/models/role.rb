class Role < ActiveRecord::Base

  attr_accessible :permissions, :name, :collaborator_ids
  validates_presence_of :name
  belongs_to :account
  has_and_belongs_to_many :collaborators
  serialize :permissions
  before_save :empty_permissions_check

  def to_s
    name
  end

  def empty_permissions_check
    self.permissions = {} if permissions.nil?
  end

end
