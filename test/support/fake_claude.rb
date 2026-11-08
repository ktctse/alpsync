# Stands in for Anthropic::Client in tests: returns a canned reply and records
# the request, so tests never call the real API.
class FakeClaude
  Block = Struct.new(:type, :text)
  Reply = Struct.new(:stop_reason, :content)

  attr_reader :requests

  def initialize(reply: {}, stop_reason: :end_turn, error: nil)
    @reply = reply
    @stop_reason = stop_reason
    @error = error
    @requests = []
  end

  def beta = self
  def messages = self

  def create(**request)
    @requests << request
    raise @error if @error

    Reply.new(@stop_reason, [ Block.new(:text, @reply.to_json) ])
  end
end
