# One chat message. Saving it pushes it to everyone viewing the conversation
# (Turbo Streams over Action Cable), so both riders see it straight away.
class Message < ApplicationRecord
  MAX_LENGTH = 1000
  # A short pause before a sample rider's automatic reply, so it arrives after
  # the rider's own message, the way a real reply would.
  SAMPLE_REPLY_DELAY = 2.seconds

  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: "Trip"

  before_validation { self.body = body.to_s.strip }

  validates :body, presence: true, length: { maximum: MAX_LENGTH }
  validate :sender_in_conversation

  after_create_commit -> { broadcast_append_to conversation, target: "messages" }
  after_create_commit :ask_sample_rider_to_reply
  after_destroy_commit -> { broadcast_remove_to conversation }

  private

  def ask_sample_rider_to_reply
    recipient = conversation.other(sender)
    return unless recipient.demo? && !sender.demo?
    return unless conversation.messages.where(sender:).count == 1 # first message only

    SampleReplyJob.set(wait: SAMPLE_REPLY_DELAY).perform_later(conversation, recipient)
  end

  def sender_in_conversation
    errors.add(:sender, "isn't part of this conversation") unless conversation&.participant?(sender)
  end
end
