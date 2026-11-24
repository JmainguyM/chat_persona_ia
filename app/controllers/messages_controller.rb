class MessagesController < ApplicationController
  rescue_from RubyLLM::Error, with: :ai_error

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = Message.new(message_params.merge(chat: @chat, role: "user"))

    if @message.save
      @chat.reply_to(@message)
      @chat.refresh_suggestions!
      redirect_to chat_path(@chat)
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def ai_error(error)
    Rails.logger.error("AI reply failed for chat #{@chat.id}: #{error.message}")
    redirect_to chat_path(@chat), alert: "The AI couldn't answer, please try again."
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
