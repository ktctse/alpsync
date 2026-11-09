class MessagesController < ApplicationController
  rate_limit to: 20, within: 1.minute, only: :create,
             with: -> { render turbo_stream: turbo_stream.update("message_error", "You're sending messages quickly. Wait a moment.") }

  before_action :set_conversation

  def create
    message = @conversation.messages.create(sender: my_trip, body: params.expect(message: [ :body ])[:body])
    @conversation.read_by!(my_trip)

    # The new message also reaches both riders through the broadcast; Turbo
    # skips the duplicate because both copies share the same id.
    render turbo_stream: [
      (turbo_stream.append("messages", message) if message.persisted?),
      turbo_stream.replace("message_form", partial: "messages/form",
                           locals: { conversation: @conversation, message: message.persisted? ? Message.new : message })
    ].compact
  end

  # Riders can delete their own messages; it disappears for both of them.
  def destroy
    message = @conversation.messages.where(sender: my_trip).find(params[:id])
    message.destroy!
    render turbo_stream: turbo_stream.remove(message)
  end

  private

  def set_conversation
    return head :not_found unless my_trip

    @conversation = Conversation.involving(my_trip).find_by(id: params[:conversation_id])
    # Deleted because one of the riders unmatched (or deleted their trip)
    # (Turbo still shows a stream response that comes with an error status.)
    unless @conversation
      render turbo_stream: turbo_stream.update("message_error", "This chat has ended, so nothing was sent."), status: :not_found
    end
  end
end
