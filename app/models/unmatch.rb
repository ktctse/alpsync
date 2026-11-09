# One rider unmatching another. It works both ways: the two drop out of each
# other's matches, their chat is deleted, and neither can message the other.
class Unmatch < ApplicationRecord
  belongs_to :trip
  belongs_to :other_trip, class_name: "Trip"

  def self.unmatch!(trip, other)
    transaction do
      create_or_find_by!(trip:, other_trip: other)
      first, second = [ trip.id, other.id ].sort
      Conversation.where(trip_a_id: first, trip_b_id: second).destroy_all
    end
  end
end
