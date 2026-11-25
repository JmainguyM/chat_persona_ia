class ChatsController < ApplicationController
  before_action :require_credits_left!, only: :create

  def show
    # Le propriétaire de la conversation ou un invité qui a accepté
    @chat = Chat.accessible_by(current_user).find(params[:id])
    @message = Message.new
  end

  def create
    persona = Persona.find(params[:persona_id])
    # Réutilise une conversation où l'utilisateur n'a encore rien écrit (seulement le message d'accueil)
    # plutôt que d'en créer une de plus
    chat = unstarted_chat_with(persona) || start_chat_with(persona)
    redirect_to chat_path(chat)
  end

  def destroy
    chat = current_user.chats.find(params[:id])
    chat.destroy
    redirect_to dashboard_path(anchor: "conversations"),
                notice: "Conversation with #{chat.persona.name} deleted.", status: :see_other
  end

  private

  def unstarted_chat_with(persona)
    chats_with_user_messages = Message.where(role: "user").select(:chat_id)
    current_user.chats.where(persona: persona).where.not(id: chats_with_user_messages).first
  end

  def start_chat_with(persona)
    chat = current_user.chats.create!(persona: persona, title: "Chat with #{persona.name}")
    # Accueil et suggestions en arrière-plan : la page du chat s'ouvre tout de suite
    ChatStartJob.perform_later(chat)
    chat
  end
end
