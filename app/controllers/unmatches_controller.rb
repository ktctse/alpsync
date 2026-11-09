class UnmatchesController < ApplicationController
  # POST /trips/:trip_id/unmatch
  def create
    return redirect_to(new_trip_path, notice: "Post your trip first.") unless my_trip

    other = Trip.find(params[:trip_id])
    return redirect_to(other, notice: "That's your own trip.") if other == my_trip

    Unmatch.unmatch!(my_trip, other)
    redirect_to trip_path(my_trip),
                notice: "You unmatched #{other.name}. You won't see each other in your matches, and your chat is deleted."
  end
end
