# Conversation partagée : le propriétaire invite d'autres membres du site (voir Invitation).
# Regroupe l'accès des membres et ce que le persona doit savoir quand plusieurs personnes lui parlent.
module ShareableChat
  extend ActiveSupport::Concern

  included do
    has_many :invitations, dependent: :destroy
    # Membres invités qui ont accepté (le propriétaire n'en fait pas partie)
    has_many :members, -> { where(invitations: { status: "accepted" }) }, through: :invitations, source: :invitee

    # Les conversations que l'utilisateur possède, ou qu'il a rejointes
    scope :accessible_by, lambda { |user|
      where(user: user).or(where(id: Invitation.accepted.where(invitee: user).select(:chat_id)))
    }
  end

  # Au moins un invité a rejoint la conversation
  def shared?
    members.exists?
  end

  private

  # À plusieurs, le persona doit savoir que chaque message commence par le nom de son auteur
  def reply_instructions
    return persona.instructions_for_llm unless shared?

    "#{persona.instructions_for_llm}\n\nSeveral people take part in this conversation. " \
      "Each user message starts with the author's name followed by a colon. " \
      "Address people by name when relevant, but never start your own reply with a name and a colon."
  end

  # Ce qu'on envoie à l'IA : le message préfixé par le pseudo de son auteur (rien n'est changé en base)
  def content_for_llm(message)
    message.user ? "#{message.user.username}: #{message.content}" : message.content
  end
end
