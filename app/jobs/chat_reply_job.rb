# Réponse du persona à un message de l'utilisateur, en arrière-plan, puis nouvelles suggestions.
# Si l'IA ne répond pas, on prévient la page au lieu de laisser l'indicateur "typing" tourner.
class ChatReplyJob < ApplicationJob
  queue_as :default

  # Le message (ou sa conversation) a pu être supprimé entre-temps
  discard_on ActiveJob::DeserializationError

  def perform(user_message)
    chat = user_message.chat
    chat.reply_to(user_message)
    chat.refresh_suggestions!
  rescue RubyLLM::Error => e
    Rails.logger.error("AI reply failed for chat #{chat.id}: #{e.message}")
    chat.broadcast_reply_error
  end
end
