class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  # touch : met à jour chat.updated_at, pour trier les conversations par activité récente
  belongs_to :chat, touch: true

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true

  # Chaque nouveau message apparaît en direct dans la page du chat (Turbo Streams)
  after_create_commit :broadcast_to_chat

  private

  # Message de l'utilisateur : le persona "écrit" et les anciennes suggestions disparaissent.
  # Message du persona : il remplace l'indicateur "typing".
  def broadcast_to_chat
    broadcast_append_to chat, target: "messages", partial: "chats/message",
                              locals: { message: self, persona: chat.persona }
    if role == "user"
      broadcast_update_to chat, target: "typing", partial: "chats/typing", locals: { persona: chat.persona }
      broadcast_update_to chat, target: "suggestions", html: ""
    else
      broadcast_update_to chat, target: "typing", html: ""
    end
  end
end
