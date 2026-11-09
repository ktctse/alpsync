# Sample riders aren't real people. When someone messages one, it answers once
# with an automatic note, so visitors can try the whole chat (including a reply
# arriving live) before any real rider has matched with them.
class SampleReplyJob < ApplicationJob
  discard_on ActiveJob::DeserializationError # the trip was deleted meanwhile

  def perform(conversation, sample)
    return if conversation.messages.exists?(sender: sample)

    rider = conversation.other(sample)
    conversation.messages.create!(sender: sample, body: <<~REPLY.squish)
      Hey #{rider.name}! I'm #{sample.name}, one of Alpsync's sample riders, so this
      reply is automatic. When you match with real riders, their replies show up
      here live, just like this one.
    REPLY
  end
end
