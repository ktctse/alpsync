require "test_helper"

class SidebarAndSeedsTest < ActionDispatch::IntegrationTest
  def seed = capture_io { load Rails.root.join("db/seeds.rb") }

  test "the sidebar lists riders on the mountain now and the newest posts" do
    Trip.create!(
      name: "Hana", resort: "Niseko United", starts_on: Date.current - 1, ends_on: Date.current + 3,
      skill_level: "advanced", languages: %w[English], looking_for: %w[ride_buddy],
      contact_method: "email", contact_handle: "hana@example.com"
    )
    Trip.create!(
      name: "Owen", resort: "Sun Peaks", starts_on: Date.current + 40, ends_on: Date.current + 42,
      skill_level: "intermediate", languages: %w[English], looking_for: %w[ride_buddy],
      contact_method: "email", contact_handle: "owen@example.com"
    )

    get root_path
    assert_select "aside section:first-child", text: /On the mountain now.*Hana/m
    assert_select "aside section:first-child", text: /Owen/, count: 0
    assert_select "aside section:last-child", text: /Just posted.*Owen.*Hana/m
    assert_no_match "hana@example.com", response.body
  end

  test "seeding is repeatable, renews ended sample trips and leaves real trips alone" do
    real = Trip.create!(
      name: "Real rider", resort: "Hakuba Goryu", starts_on: Date.current + 5, ends_on: Date.current + 6,
      skill_level: "beginner", languages: %w[English], looking_for: %w[instructor],
      contact_method: "email", contact_handle: "real@example.com"
    )

    seed
    count = Trip.demo.count
    seed
    assert_equal count, Trip.demo.count

    travel_to 120.days.from_now do
      seed
      assert_equal count, Trip.demo.upcoming.count
      assert Trip.demo.find_by(name: "Hana").starts_on <= Date.current
    end
    assert_equal "Real rider", real.reload.name
  end
end
