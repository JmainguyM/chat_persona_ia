class ChatsController < ApplicationController
  def show
    @chat = current_user.chats.find(params[:id])
    @message = Message.new
  end

  def create
    persona = Persona.find(params[:persona_id])
    chat = current_user.chats.create!(persona: persona, title: "Chat with #{persona.name}")
    chat.greet!
    redirect_to chat_path(chat)
  end
end
