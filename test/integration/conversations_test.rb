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

  test "visitors see matches and messages locked, with a hint on how to unlock them" do
    get root_path
    assert_select "header nav a[href=?]", conversations_path, 0
    assert_select "header nav span.cursor-not-allowed", text: "Matches"
    assert_select "header nav span.cursor-not-allowed", text: "Messages"
    assert_select "header [data-controller=hint] button[aria-describedby=locked_hint]"
    assert_select "#locked_hint[role=tooltip]", text: /Post a trip to unlock your matches and messages/

    wing, wing_browser = rider("Wing")
    wing_browser.get root_path
    header = wing_browser.response.parsed_body.at_css("header nav")
    assert header.at_css("a[href='#{conversations_path}']"), "Messages is a real link"
    assert header.at_css("a[href='#{trip_path(wing)}']"), "Matches is a real link"
    assert_nil header.at_css("#locked_hint")
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

  test "messaging a sample rider gets one automatic reply, pushed live" do
    wing, wing_browser = rider("Wing")
    ryan, = rider("Ryan", demo: true)

    wing_browser.post trip_conversation_path(ryan)
    conversation = Conversation.between(wing, ryan)
    assert_equal conversation_path(conversation), URI(wing_browser.response.location).path

    2.times do
      wing_browser.post conversation_messages_path(conversation), params: { message: { body: "Hi Ryan" } }, headers: turbo_stream
    end
    assert_enqueued_jobs 1, only: SampleReplyJob

    assert_turbo_stream_broadcasts conversation, count: 1 do
      perform_enqueued_jobs only: SampleReplyJob
    end
    reply = conversation.messages.last
    assert_equal ryan, reply.sender
    assert_match "Hey Wing! I'm Ryan, one of Alpsync's sample riders", reply.body
  end

  test "real riders don't get automatic replies" do
    wing, wing_browser = rider("Wing")
    mika, = rider("Mika")
    conversation = Conversation.between(wing, mika)

    wing_browser.post conversation_messages_path(conversation), params: { message: { body: "Hi" } }, headers: turbo_stream
    assert_no_enqueued_jobs only: SampleReplyJob
  end

  test "unmatching drops both riders from each other's matches and ends their chat" do
    wing, wing_browser = rider("Wing")
    mika, mika_browser = rider("Mika", contact_method: "line", contact_handle: "mika-line")
    conversation = Conversation.between(wing, mika)
    conversation.messages.create!(sender: mika, body: "Hi Wing")
    assert_includes wing.matches.map(&:trip), mika

    wing_browser.post trip_unmatch_path(mika)
    assert_equal trip_path(wing), URI(wing_browser.response.location).path

    assert_not Conversation.exists?(conversation.id)
    assert_equal 0, Message.count
    assert_not_includes Trip.find(wing.id).matches.map(&:trip), mika
    assert_not_includes Trip.find(mika.id).matches.map(&:trip), wing, "it works both ways"

    # Mika can't start a new chat, and the old one has gone
    mika_browser.post trip_conversation_path(wing)
    assert_equal trip_path(wing), URI(mika_browser.response.location).path
    assert_equal 0, Conversation.count
    mika_browser.post conversation_messages_path(conversation), params: { message: { body: "Hello?" } }, headers: turbo_stream
    assert_match "This chat has ended", mika_browser.response.body

    # Wing sees Mika's trip without the message button or contact handle
    wing_browser.get trip_path(mika)
    assert_match "Unmatched", wing_browser.response.body
    assert_no_match "mika-line", wing_browser.response.body
  end

  test "riders can delete their own messages, and it disappears for both" do
    wing, wing_browser = rider("Wing")
    mika, mika_browser = rider("Mika")
    conversation = Conversation.between(wing, mika)
    mine = conversation.messages.create!(sender: wing, body: "Wrong chat, sorry")
    theirs = conversation.messages.create!(sender: mika, body: "Hi Wing")

    assert_turbo_stream_broadcasts conversation, count: 1 do
      wing_browser.delete conversation_message_path(conversation, mine), headers: turbo_stream
    end
    assert_match %(action="remove" target="#{ActionView::RecordIdentifier.dom_id(mine)}"), wing_browser.response.body
    assert_not Message.exists?(mine.id)

    wing_browser.delete conversation_message_path(conversation, theirs), headers: turbo_stream
    assert_equal 404, wing_browser.response.status
    assert Message.exists?(theirs.id), "can't delete the other rider's messages"

    mika_browser.get conversation_path(conversation)
    assert_no_match "Wrong chat, sorry", mika_browser.response.body
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
