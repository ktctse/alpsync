# A private chat between two riders, identified by their trips (riders have no
# accounts). Only the two trips' owners can open it.
class Conversation < ApplicationRecord
  belongs_to :trip_a, class_name: "Trip"
  belongs_to :trip_b, class_name: "Trip"
  has_many :messages, -> { order(:created_at) }, dependent: :delete_all

  scope :involving, ->(trip) { where(trip_a: trip).or(where(trip_b: trip)) }

  # The one conversation between two trips, created the first time it's needed.
  def self.between(one, other)
    first, second = [ one, other ].sort_by(&:id)
    find_or_create_by!(trip_a: first, trip_b: second)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def participant?(trip) = trip.present? && [ trip_a_id, trip_b_id ].include?(trip.id)

  def other(trip) = trip.id == trip_a_id ? trip_b : trip_a

  def read_by!(trip)
    update_column(read_column(trip), Time.current)
  end

  # Has the other rider written since this trip's owner last opened the chat?
  def unread_for?(trip)
    read_at = self[read_column(trip)]
    messages.where.not(sender: trip).where(created_at: (read_at || Time.at(0))..).exists?
  end

  def report!
    update!(reported_at: Time.current)
    Rails.logger.warn("Conversation #{id} reported for review")
  end

  private

  def read_column(trip) = trip.id == trip_a_id ? :trip_a_read_at : :trip_b_read_at
end
