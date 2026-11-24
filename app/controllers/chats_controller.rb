class ChatsController < ApplicationController
  def index
    @chats = current_user.chats.includes(:persona).order(updated_at: :desc)
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @message = Message.new
  end

  def create
    persona = Persona.find(params[:persona_id])
    chat = current_user.chats.create!(persona: persona, title: "Chat with #{persona.name}")
    redirect_to chat_path(chat)
  end
end
