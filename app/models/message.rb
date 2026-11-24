class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  # touch : met à jour chat.updated_at, pour trier les conversations par activité récente
  belongs_to :chat, touch: true

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true
end
