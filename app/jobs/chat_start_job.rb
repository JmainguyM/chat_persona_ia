# Démarre une conversation en arrière-plan : message d'accueil du persona, puis suggestions.
# Les messages arrivent dans la page via Turbo Streams (voir Message#broadcast_to_chat).
class ChatStartJob < ApplicationJob
  queue_as :default

  # La conversation a pu être supprimée entre-temps
  discard_on ActiveJob::DeserializationError

  def perform(chat)
    chat.greet!
    chat.refresh_suggestions!
  end
end
