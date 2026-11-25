class User < ApplicationRecord
  has_many :personas, dependent: :destroy
  has_many :chats, dependent: :destroy

  enum :status, { base: "base", premium: "premium", admin: "admin" }, default: "base", validate: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  validates :username, presence: true, uniqueness: true
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
