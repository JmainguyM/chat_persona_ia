class Invitation < ApplicationRecord
  STATUSES = %w[pending accepted declined].freeze

  belongs_to :chat
  belongs_to :inviter, class_name: "User"
  belongs_to :invitee, class_name: "User"

  validates :status, inclusion: { in: STATUSES }
  validates :invitee_id, uniqueness: { scope: :chat_id, message: "is already invited" }
  validate :invitee_is_not_owner

  scope :pending,  -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  # Nouvelle invitation (ou ré-invitation après un refus) : elle apparaît en direct sur le dashboard de l'invité
  after_save_commit :broadcast_to_invitee, if: -> { status == "pending" }

  def pending?
    status == "pending"
  end

  def declined?
    status == "declined"
  end

  private

  def invitee_is_not_owner
    errors.add(:invitee, "already owns this chat") if invitee_id == chat&.user_id
  end

  # Remplace toute la liste : elle peut être vide (donc absente de la page) avant cette invitation
  def broadcast_to_invitee
    broadcast_replace_to [invitee, :invitations], target: "invitations", partial: "pages/invitations",
                                                  locals: { invitations: invitee.received_invitations.pending
                                                                                .includes(:inviter, chat: :persona) }
  end
end
