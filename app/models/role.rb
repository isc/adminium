class Role < ActiveRecord::Base

  attr_accessible :permissions, :name, :collaborator_ids
  validates_presence_of :name
  belongs_to :account
  has_and_belongs_to_many :collaborators
  serialize :permissions

  def to_s
    name
  end

end
