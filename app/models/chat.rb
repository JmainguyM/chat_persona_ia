class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :persona
  has_many :messages, -> { order(:created_at) }, dependent: :destroy
end
