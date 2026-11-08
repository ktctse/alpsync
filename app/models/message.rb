# One chat message. Saving it pushes it to everyone viewing the conversation
# (Turbo Streams over Action Cable), so both riders see it straight away.
class Message < ApplicationRecord
  MAX_LENGTH = 1000

  belongs_to :conversation, touch: true
  belongs_to :sender, class_name: "Trip"

  before_validation { self.body = body.to_s.strip }

  validates :body, presence: true, length: { maximum: MAX_LENGTH }
  validate :sender_in_conversation

  after_create_commit -> { broadcast_append_to conversation, target: "messages" }

  private

  def sender_in_conversation
    errors.add(:sender, "isn't part of this conversation") unless conversation&.participant?(sender)
  end
end
