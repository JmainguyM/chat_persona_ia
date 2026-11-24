class Persona < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy
  # Photo uploadée, stockée sur Cloudinary via Active Storage
  has_one_attached :photo

  # built_in : personas de base livrés avec l'app, que personne ne peut modifier ni supprimer
  scope :built_in, -> { where(built_in: true) }
  scope :custom, -> { where(built_in: false) }

  validates :name, presence: true
  validates :system_prompt, presence: true

  def editable_by?(user)
    !built_in? && user_id == user&.id
  end
end
