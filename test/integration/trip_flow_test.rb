require "test_helper"

class TripFlowTest < ActionDispatch::IntegrationTest
  setup do
    @mika = Trip.create!(
      name: "Mika", resort: "Hakuba Happo-one", starts_on: Date.current + 30, ends_on: Date.current + 33,
      skill_level: "intermediate", languages: %w[English], looking_for: %w[lodge_mate], offering: %w[driver],
      contact_method: "line", contact_handle: "mika-line"
    )
  end

  test "posting a trip shows ranked matches and unlocks contact details" do
    get trip_path(@mika)
    assert_response :success
    assert_no_match "mika-line", response.body

    post trips_path, params: { trip: {
      name: "Wing", resort: "Hakuba Happo-one", starts_on: Date.current + 30, ends_on: Date.current + 34,
      skill_level: "intermediate", party_size: 1, languages: %w[English], looking_for: %w[driver lodge_mate],
      contact_method: "email", contact_handle: "wing@example.com"
    } }
    wing = Trip.find_by!(name: "Wing")
    assert_redirected_to trip_path(wing)

    follow_redirect!
    assert_select "h2", "Your matches"
    assert_match "They can offer what you need: Driver", response.body
    assert_match "Mutual match", response.body
    assert_match "mika-line", response.body
  end

  test "the private link edits and deletes a trip" do
    get manage_trip_path(@mika.edit_token)
    assert_response :success

    patch manage_trip_path(@mika.edit_token), params: { trip: { note: "Two seats free" } }
    assert_redirected_to trip_path(@mika)
    assert_equal "Two seats free", @mika.reload.note

    delete manage_trip_path(@mika.edit_token)
    assert_redirected_to root_path
    assert_not Trip.exists?(@mika.id)
  end

  test "the banner slides through three photos" do
    get root_path
    assert_select "[data-controller=slideshow] [data-slideshow-target=track] img", 3
  end

  test "the page ends with the Everest motion graphic" do
    get root_path
    assert_select "[data-controller=everest] canvas[role=img][aria-label]"
    assert_select "[data-controller=everest]", text: /Everest, 8,849 m/
  end

  test "an unknown private link is not found" do
    get manage_trip_path("not-a-real-token")
    assert_response :not_found
  end

  test "an invalid trip re-renders the form with errors" do
    post trips_path, params: { trip: { name: "", resort: "Nowhere", contact_method: "email" } }
    assert_response :unprocessable_entity
    assert_select "li", text: "Name can't be blank"
    assert_select "li", text: "Resort isn't on our list yet"
  end

  test "the feed filters by region and tag" do
    Trip.create!(
      name: "Ada", resort: "Kiroro", starts_on: Date.current + 50, ends_on: Date.current + 55,
      skill_level: "intermediate", languages: %w[English], looking_for: %w[ride_buddy], offering: %w[driver],
      contact_method: "email", contact_handle: "ada@example.com"
    )

    get trips_path, params: { region: "Hokkaido", tag: "driver" }
    assert_select "turbo-frame#trips article", 1
    assert_select "turbo-frame#trips", text: /Ada/
    assert_select "turbo-frame#trips", text: /Mika/, count: 0
  end
end
