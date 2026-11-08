class TripsController < ApplicationController
  TRIPS_PER_PAGE = 10
  NEW_TRIP_DEFAULTS = { party_size: 1, skill_level: "intermediate", contact_method: "whatsapp" }.freeze

  before_action :set_trip_by_token, only: %i[edit update destroy]

  # Each draft is a paid Claude API call, so cap how often one visitor can ask.
  rate_limit to: 5, within: 1.minute, only: :draft,
             with: -> { render_draft_status("That's a few tries in a row. Wait a minute, or fill the form in by hand.") }
  rate_limit to: 30, within: 1.day, only: :draft, name: "daily",
             with: -> { render_draft_status("You've hit today's limit for pasted messages. Fill the form in by hand.") }

  def index
    @filters = params.permit(:region, :language, :tag, :on)
    trips = filtered_trips
    @total = trips.count
    @pages = [ (@total / TRIPS_PER_PAGE.to_f).ceil, 1 ].max
    @page = params[:page].to_i.clamp(1, @pages)
    @trips = trips.offset((@page - 1) * TRIPS_PER_PAGE).limit(TRIPS_PER_PAGE)
    @on_the_mountain = Trip.upcoming.where(starts_on: ..Date.current).order(:ends_on).limit(5)
    @just_posted = Trip.upcoming.newest_first.limit(5)
  end

  def show
    @trip = Trip.find(params[:id])
    @mine = @trip == my_trip
    @matches = @trip.matches if @mine
  end

  def new
    @trip = Trip.new(resort: params[:resort], **NEW_TRIP_DEFAULTS)
  end

  # Reads a pasted group-chat message with Claude and refills the form for the
  # rider to check. Nothing is saved until they post it themselves.
  def draft
    @trip = Trip.new(NEW_TRIP_DEFAULTS.merge(TripDraft.new(params[:message]).attributes))
    render turbo_stream: [
      turbo_stream.update("trip_form", partial: "form", locals: { trip: @trip }),
      turbo_stream.update("draft_status", "Filled in from your message. Check everything, then post.")
    ]
  rescue TripDraft::Error => error
    render_draft_status(error.message)
  end

  def create
    @trip = Trip.new(trip_params)
    if @trip.save
      remember(@trip)
      redirect_to @trip, notice: "Your trip is live. Here's who fits it."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @trip.update(trip_params)
      redirect_to @trip, notice: "Trip updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trip.destroy
    cookies.delete(:trip_token)
    redirect_to root_path, notice: "Trip deleted."
  end

  private

  def render_draft_status(message)
    render turbo_stream: turbo_stream.update("draft_status", message)
  end

  def filtered_trips
    trips = Trip.upcoming.order(:starts_on)
    trips = trips.where(region: @filters[:region]) if @filters[:region].present?
    trips = trips.where("? = ANY(languages)", @filters[:language]) if @filters[:language].present?
    trips = trips.where("? = ANY(looking_for) OR ? = ANY(offering)", @filters[:tag], @filters[:tag]) if @filters[:tag].present?
    if (day = Date.parse(@filters[:on].to_s) rescue nil)
      trips = trips.where("starts_on <= :day AND ends_on >= :day", day:)
    end
    trips
  end

  # Opening the private edit link also remembers this browser as the trip's owner.
  def set_trip_by_token
    @trip = Trip.find_by!(edit_token: params[:token])
    remember(@trip)
  end

  def trip_params
    params.expect(trip: [ :name, :resort, :starts_on, :ends_on, :party_size, :skill_level,
                          :contact_method, :contact_handle, :note,
                          languages: [], looking_for: [], offering: [] ])
  end
end
