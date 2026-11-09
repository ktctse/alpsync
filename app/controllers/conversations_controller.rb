# Chat between two riders. Riders have no accounts, so "you" are the trip this
# browser posted (remembered from its private link), and you can only open the
# conversations that trip is part of.
class ConversationsController < ApplicationController
  before_action :require_my_trip

  def index
    @conversations = Conversation.involving(my_trip).includes(:trip_a, :trip_b).order(updated_at: :desc)
  end

  def show
    @conversation = Conversation.involving(my_trip).find(params[:id])
    @other = @conversation.other(my_trip)
    @messages = @conversation.messages.includes(:sender)
    @conversation.read_by!(my_trip)
  end

  # POST /trips/:trip_id/conversation: open (or reopen) the chat with that trip.
  def create
    other = Trip.upcoming.find(params[:trip_id])
    if other == my_trip
      redirect_to other, notice: "That's your own trip."
    elsif my_trip.unmatched_with?(other)
      redirect_to other, notice: "You and #{other.name} are unmatched, so you can't message each other."
    else
      redirect_to Conversation.between(my_trip, other)
    end
  end

  def report
    conversation = Conversation.involving(my_trip).find(params[:id])
    conversation.report!
    redirect_to conversation, notice: "Thanks. This conversation has been flagged for review."
  end

  private

  def require_my_trip
    redirect_to new_trip_path, notice: "Post your trip first to message other riders." unless my_trip
  end
end
