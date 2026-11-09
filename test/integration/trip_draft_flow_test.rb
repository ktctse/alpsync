require "test_helper"
require "support/fake_claude"

class TripDraftFlowTest < ActionDispatch::IntegrationTest
  teardown do
    TripDraft.client = nil
    DraftUsage.daily_limit = 50
  end

  test "the paste box only shows once Claude is configured" do
    TripDraft.client = nil
    with_env("ANTHROPIC_API_KEY" => nil) do
      get new_trip_path
      assert_select "textarea[name=message]", 0
    end

    TripDraft.client = FakeClaude.new
    get new_trip_path
    assert_select "textarea[name=message]"
  end

  test "pasting a message refills the form for the rider to check" do
    TripDraft.client = FakeClaude.new(reply: {
      "name" => "Wing", "resorts" => [ "Niseko United", "Rusutsu" ], "looking_for" => %w[driver], "languages" => %w[Cantonese]
    })

    post draft_trips_path, params: { message: "Niseko 12-15 Jan, need a ride, Cantonese ok" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match 'turbo-stream action="update" target="trip_form"', response.body
    assert_match 'value="Wing"', response.body
    assert_match(/value="Niseko United"[^>]*checked="checked"/, response.body)
    assert_match(/value="Rusutsu"[^>]*checked="checked"/, response.body)
    assert_match "Check everything, then post", response.body
    assert_equal 0, Trip.count, "nothing is saved until the rider posts"
  end

  test "a failed read shows a message instead of breaking the form" do
    TripDraft.client = FakeClaude.new(stop_reason: :refusal)

    post draft_trips_path, params: { message: "hello" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match 'target="draft_status"', response.body
    assert_no_match 'target="trip_form"', response.body
  end

  test "a site-wide daily cap stops Claude calls whoever is asking" do
    fake = TripDraft.client = FakeClaude.new(reply: { "name" => "Wing" })
    DraftUsage.daily_limit = 2

    3.times { post draft_trips_path, params: { message: "Niseko next week" }, headers: { "Accept" => "text/vnd.turbo-stream.html" } }

    assert_equal 2, fake.requests.size
    assert_match "today's limit for the whole site", response.body
  end

  test "a blank paste doesn't use up the daily allowance" do
    TripDraft.client = FakeClaude.new

    post draft_trips_path, params: { message: "  " }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_match "Paste a message first", response.body
    assert_equal 0, DraftUsage.sum(:count)
  end

  private

  def with_env(values)
    saved = values.keys.index_with { |key| ENV[key] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    saved.each { |key, value| ENV[key] = value }
  end
end
