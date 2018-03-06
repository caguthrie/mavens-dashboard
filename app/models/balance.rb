class Balance < ApplicationRecord
  belongs_to :player
  validates_uniqueness_of :date, scope: :player_id
end
