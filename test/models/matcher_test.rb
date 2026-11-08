require "test_helper"

class MatcherTest < ActiveSupport::TestCase
  def trip(name, **overrides)
    Trip.create!({
      name:, resort: "Hakuba Happo-one", starts_on: Date.current + 30, ends_on: Date.current + 34,
      skill_level: "intermediate", languages: %w[English], looking_for: %w[ride_buddy], offering: [],
      contact_method: "email", contact_handle: "#{name}@example.com"
    }.merge(overrides))
  end

  test "a rider who covers my need and needs what I offer is a mutual match ranked first" do
    me = trip("me", looking_for: %w[driver], offering: %w[japanese])
    driver_only = trip("driver_only", looking_for: %w[gear], offering: %w[driver])
    mutual = trip("mutual", looking_for: %w[japanese], offering: %w[driver])

    matches = me.matches
    assert_equal [ mutual, driver_only ], matches.map(&:trip)
    assert matches.first.mutual
    assert_not matches.last.mutual
    assert_includes matches.first.reasons, "They can offer what you need: Driver"
  end

  test "a shared plan such as lodge mates is a match, but only mutual alongside a covered need" do
    me = trip("me", looking_for: %w[lodge_mate driver])
    plan_only = trip("plan_only", looking_for: %w[lodge_mate])
    plan_and_car = trip("plan_and_car", looking_for: %w[lodge_mate], offering: %w[driver])

    matches = me.matches
    assert_equal [ plan_and_car, plan_only ], matches.map(&:trip)
    assert matches.first.mutual
    assert_not matches.last.mutual
    assert_includes matches.last.reasons, "You both want a lodge mate"
  end

  test "a spare room on offer matches a rider looking for one" do
    me = trip("me", looking_for: %w[room])
    host = trip("host", looking_for: %w[ride_buddy], offering: %w[room])

    match = me.matches.sole
    assert_equal host, match.trip
    assert_includes match.reasons, "They can offer what you need: Spare room"
  end

  test "riders without a shared language, overlapping dates or region are never matched" do
    me = trip("me", looking_for: %w[driver])
    trip("no_language", offering: %w[driver], languages: %w[Korean])
    trip("other_dates", offering: %w[driver], starts_on: Date.current + 60, ends_on: Date.current + 62)
    trip("other_region", offering: %w[driver], resort: "Whistler Blackcomb")

    assert_empty me.matches
  end

  test "same dates and region without any tag overlap is not a match" do
    me = trip("me", looking_for: %w[driver])
    trip("unrelated", looking_for: %w[instructor])

    assert_empty me.matches
  end
end
