class MessagesController < ApplicationController
  rate_limit to: 20, within: 1.minute,
             with: -> { render turbo_stream: turbo_stream.update("message_error", "You're sending messages quickly. Wait a moment.") }

  def create
    return head :not_found unless my_trip

    conversation = Conversation.involving(my_trip).find(params[:conversation_id])
    message = conversation.messages.create(sender: my_trip, body: params.expect(message: [ :body ])[:body])
    conversation.read_by!(my_trip)

    # The new message also reaches both riders through the broadcast; Turbo
    # skips the duplicate because both copies share the same id.
    render turbo_stream: [
      (turbo_stream.append("messages", message) if message.persisted?),
      turbo_stream.replace("message_form", partial: "messages/form",
                           locals: { conversation:, message: message.persisted? ? Message.new : message })
    ].compact
  end
end
