class Friendship < ApplicationRecord
  after_create :create_inverse_relationship
  after_destroy :destroy_inverse_relationship

  belongs_to :player
  belongs_to :friend, class_name: 'Player'

  validate :not_self

  private

  def create_inverse_relationship
    friendship = friend.friendships.find_by(friend: player)
    friend.friendships.create(friend: player) unless friendship
  end

  def destroy_inverse_relationship
    friendship = friend.friendships.find_by(friend: player)
    friendship.destroy if friendship
  end

  def not_self
    errors.add(:friend, "can't be equal to user") if player == friend
  end
end
