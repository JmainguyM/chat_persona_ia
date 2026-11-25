class MessagesController < ApplicationController
  before_action :set_chat
  before_action :require_credits_left!, only: :create

  def create
    # Un seul message à la fois : on attend la réponse du persona avant d'en envoyer un autre
    return head :conflict if @chat.awaiting_reply?

    @message = Message.new(message_params.merge(chat: @chat, role: "user"))
    return render("chats/show", status: :unprocessable_entity) unless @message.save

    # La réponse de l'IA est demandée en arrière-plan et arrive dans la page via Turbo Streams
    ChatReplyJob.perform_later(@message)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to chat_path(@chat) }
    end
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
