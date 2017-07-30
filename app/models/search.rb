class Search < ApplicationRecord
  belongs_to :account
  validates :name, :table, presence: true
end
