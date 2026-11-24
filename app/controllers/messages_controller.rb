class MessagesController < ApplicationController
  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = @chat.messages.new(message_params.merge(role: "user"))

    if @message.save
      # TODO: call the AI with the persona's system prompt and the chat history, then save its reply.
      redirect_to chat_path(@chat)
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
