class Player < ApplicationRecord
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships

  has_many :balances
  has_many :pnls

  validates_uniqueness_of :username
end
