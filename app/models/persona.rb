class Persona < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :system_prompt, presence: true
end
