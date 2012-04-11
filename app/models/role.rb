class Role < ActiveRecord::Base
  attr_accessible :permissions, :name, :user_ids
  validates_presence_of :name
  belongs_to :account
  has_and_belongs_to_many :users
  serialize :permissions
end
