class Persona < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy

  validates :name, presence: true
  validates :system_prompt, presence: true
end
