class ChatsController < ApplicationController
  def show
    @chat = current_user.chats.find(params[:id])
    @message = Message.new
  end

  def create
    persona = Persona.find(params[:persona_id])
    # Réutilise une conversation où l'utilisateur n'a encore rien écrit (seulement le message d'accueil)
    # plutôt que d'en créer une de plus
    chat = unstarted_chat_with(persona) || start_chat_with(persona)
    redirect_to chat_path(chat)
  end

  private

  def unstarted_chat_with(persona)
    chats_with_user_messages = Message.where(role: "user").select(:chat_id)
    current_user.chats.where(persona: persona).where.not(id: chats_with_user_messages).first
  end

  def start_chat_with(persona)
    chat = current_user.chats.create!(persona: persona, title: "Chat with #{persona.name}")
    chat.greet!
    chat.refresh_suggestions!
    chat
  end
end
