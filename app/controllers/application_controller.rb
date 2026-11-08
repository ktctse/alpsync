class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :my_trip, :can_see_contact?, :unread_messages?

  private

  # Riders have no accounts. A signed cookie holding the edit token marks this
  # browser as the owner of one trip.
  def my_trip
    return @my_trip if defined?(@my_trip)

    token = cookies.signed[:trip_token]
    @my_trip = token.present? ? Trip.upcoming.find_by(edit_token: token) : nil
  end

  def remember(trip)
    cookies.signed.permanent[:trip_token] = { value: trip.edit_token, httponly: true }
  end

  # Contact details are only shown to riders who have posted a trip themselves,
  # so anonymous visitors and scrapers can't harvest phone numbers.
  def can_see_contact?(trip)
    my_trip.present? || trip == my_trip
  end

  # For the dot on "Messages" in the header.
  def unread_messages?
    return false unless my_trip

    @unread_messages = Conversation.involving(my_trip).any? { |conversation| conversation.unread_for?(my_trip) } unless defined?(@unread_messages)
    @unread_messages
  end
end
