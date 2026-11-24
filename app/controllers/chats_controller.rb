class ChatsController < ApplicationController
  def show
    @chat = current_user.chats.find(params[:id])
    @message = Message.new
  end

  def create
    persona = Persona.find(params[:persona_id])
    # Réutilise une conversation encore vide avec ce persona plutôt que d'en créer une de plus
    chat = current_user.chats.where(persona: persona).where.missing(:messages).first ||
           current_user.chats.create!(persona: persona, title: "Chat with #{persona.name}")
    redirect_to chat_path(chat)
  end
end
