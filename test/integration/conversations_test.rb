require "test_helper"
require "turbo/broadcastable/test_helper"

class ConversationsTest < ActionDispatch::IntegrationTest
  include Turbo::Broadcastable::TestHelper

  # A rider is a trip plus a browser session that owns it (opening the
  # private link remembers the browser, just like on the real site).
  def rider(name, **attributes)
    trip = Trip.create!({
      name:, resort: "Hakuba Happo-one", starts_on: Date.current + 30, ends_on: Date.current + 34,
      skill_level: "intermediate", languages: %w[English], looking_for: %w[ride_buddy]
    }.merge(attributes))
    session = open_session
    session.get manage_trip_path(trip.edit_token)
    [ trip, session ]
  end

  def turbo_stream = { "Accept" => "text/vnd.turbo-stream.html" }

  test "two riders can chat, and the message is pushed live to the conversation" do
    wing, wing_browser = rider("Wing")
    mika, mika_browser = rider("Mika")

    wing_browser.post trip_conversation_path(mika)
    conversation = Conversation.between(wing, mika)
    assert_equal conversation_path(conversation), URI(wing_browser.response.location).path

    assert_turbo_stream_broadcasts conversation, count: 1 do
      wing_browser.post conversation_messages_path(conversation), params: { message: { body: "Driving from Nagano, want a lift?" } },
                                                                  headers: turbo_stream
    end
    assert_match "Driving from Nagano, want a lift?", wing_browser.response.body

    mika_browser.get conversations_path
    assert_match "Driving from Nagano, want a lift?", mika_browser.response.body
    assert_match "Unread", mika_browser.response.body

    mika_browser.get conversation_path(conversation)
    assert_match "Driving from Nagano, want a lift?", mika_browser.response.body
    assert_not conversation.reload.unread_for?(mika)
  end

  test "the private link leads to your messages from the trip and edit pages" do
    wing, wing_browser = rider("Wing")
    mika, = rider("Mika")
    Conversation.between(wing, mika).messages.create!(sender: mika, body: "Hi Wing")

    wing_browser.get manage_trip_path(wing.edit_token)
    assert_match %r{href="/conversations"[^>]*>\s*Your messages \(1\)}, wing_browser.response.body
    assert_match "Unread messages", wing_browser.response.body

    wing_browser.get trip_path(wing)
    assert_match %r{href="/conversations"[^>]*>\s*Your messages \(1\)}, wing_browser.response.body
  end

  test "riders outside a conversation can't read or write in it" do
    wing, = rider("Wing")
    mika, = rider("Mika")
    _, stranger_browser = rider("Stranger")
    conversation = Conversation.between(wing, mika)

    stranger_browser.get conversation_path(conversation)
    assert_equal 404, stranger_browser.response.status

    stranger_browser.post conversation_messages_path(conversation), params: { message: { body: "hi" } }, headers: turbo_stream
    assert_equal 404, stranger_browser.response.status
    assert_empty conversation.messages
  end

  test "visitors without a trip are asked to post one first" do
    mika, = rider("Mika")

    post trip_conversation_path(mika)
    assert_redirected_to new_trip_path
  end

  test "sample riders can't be messaged" do
    _, wing_browser = rider("Wing")
    sample, = rider("Sample", demo: true)

    wing_browser.post trip_conversation_path(sample)
    assert_equal trip_path(sample), URI(wing_browser.response.location).path
    assert_equal 0, Conversation.count
  end

  test "one conversation per pair of trips, whoever starts it" do
    wing, = rider("Wing")
    mika, = rider("Mika")

    assert_equal Conversation.between(wing, mika), Conversation.between(mika, wing)
    assert_equal 1, Conversation.count
  end

  test "deleting a trip deletes its conversations and messages" do
    wing, wing_browser = rider("Wing")
    mika, = rider("Mika")
    conversation = Conversation.between(wing, mika)
    conversation.messages.create!(sender: wing, body: "Hello")

    wing_browser.delete manage_trip_path(wing.edit_token)
    assert_equal 0, Conversation.count
    assert_equal 0, Message.count
  end

  test "a trip can cover several resorts and matches riders at any of them" do
    wing, = rider("Wing", resorts: [ "Hakuba Happo-one", "Myoko Akakura" ], looking_for: %w[driver])
    myoko, = rider("Kana", resort: "Myoko Akakura", offering: %w[driver])

    assert_equal %w[Nagano Niigata], wing.regions
    match = wing.matches.sole
    assert_equal myoko, match.trip
    assert_includes match.reasons, "Same resort: Myoko Akakura"
  end
end
