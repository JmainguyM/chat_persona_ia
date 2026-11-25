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
  # Les personas des utilisateurs sont affichés en cards : sans image, la card est mal remplie.
  # Les personas de base ont leur image par défaut (PersonasHelper::DEFAULT_AVATARS).
  validate :image_present, unless: :built_in?

  def editable_by?(user)
    !built_in? && user_id == user&.id
  end

  private

  # Une photo uploadée ou une URL d'image (le formulaire n'a qu'un champ "Image" pour les deux)
  def image_present
    return if photo.attached? || avatar_url.present?

    errors.add(:avatar_url, "can't be blank: paste a link or upload a photo")
  end
end
