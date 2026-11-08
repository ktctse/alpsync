require "test_helper"
require "support/fake_claude"

class TripDraftTest < ActiveSupport::TestCase
  teardown { TripDraft.client = nil }

  def draft(reply, **fake)
    TripDraft.client = FakeClaude.new(reply:, **fake)
    TripDraft.new("Anyone heading to Hakuba Jan 10-14? I can drive.").attributes
  end

  test "keeps only values that match the form's own options" do
    attributes = draft({
      "name" => "Wing", "resorts" => [ "Hakuba Happo-one", "Zermatt" ], "starts_on" => "2027-01-10", "ends_on" => "not a date",
      "skill_level" => "intermediate", "party_size" => 20, "languages" => %w[English Klingon],
      "looking_for" => %w[lodge_mate helicopter], "offering" => %w[driver lodge_mate],
      "contact_method" => "whatsapp", "contact_handle" => "+852 5555 0000", "note" => nil
    })

    assert_equal [ "Hakuba Happo-one" ], attributes[:resorts]
    assert_equal Date.new(2027, 1, 10), attributes[:starts_on]
    assert_nil attributes[:ends_on]
    assert_equal 8, attributes[:party_size]
    assert_equal %w[English], attributes[:languages]
    assert_equal %w[lodge_mate], attributes[:looking_for]
    assert_equal %w[driver], attributes[:offering], "shared plans never go in can offer"
    assert_not attributes.key?(:note)
  end

  test "a message with only unknown resorts leaves resorts blank" do
    assert_nil draft({ "resorts" => [ "Zermatt" ] })[:resorts]
  end

  test "asks Claude for strict JSON and passes the message as the user turn" do
    fake = FakeClaude.new(reply: {})
    TripDraft.client = fake
    TripDraft.new("  Niseko next week  ").attributes

    request = fake.requests.sole
    assert_equal "claude-opus-5-5", request[:model]
    assert_equal :json_schema, request[:output_config][:format_][:type]
    assert_equal [ { role: "user", content: "Niseko next week" } ], request[:messages]
  end

  test "tells Claude the nicknames riders use for each resort" do
    fake = FakeClaude.new(reply: {})
    TripDraft.client = fake
    TripDraft.new("Revy in Feb").attributes

    instructions = fake.requests.sole[:system_]
    assert_includes instructions, "Revy: Revelstoke"
    assert_includes instructions, "Niseko, Hirafu, Hanazono, Annupuri, ニセコ: Niseko United"
  end

  test "a blank message, a refusal or an API failure becomes a friendly error" do
    assert_raises(TripDraft::Error) { TripDraft.new("   ").attributes }
    assert_raises(TripDraft::Error) { draft({}, stop_reason: :refusal) }
    assert_raises(TripDraft::Error) { draft({}, error: Anthropic::Errors::APIConnectionError.new(url: nil, request: nil)) }
  end
end
