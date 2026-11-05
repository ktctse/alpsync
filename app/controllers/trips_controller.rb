class TripsController < ApplicationController
  before_action :set_trip_by_token, only: %i[edit update destroy]

  def index
    @filters = params.permit(:region, :language, :tag, :on)
    @trips = filtered_trips
    @on_the_mountain = Trip.upcoming.where(starts_on: ..Date.current).order(:ends_on).limit(5)
    @just_posted = Trip.upcoming.newest_first.limit(5)
  end

  def show
    @trip = Trip.find(params[:id])
    @mine = @trip == my_trip
    @matches = @trip.matches if @mine
  end

  def new
    @trip = Trip.new(resort: params[:resort], party_size: 1, skill_level: "intermediate", contact_method: "whatsapp")
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
