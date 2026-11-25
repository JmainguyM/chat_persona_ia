class User < ApplicationRecord
  TOKENS_PER_CREDIT = 100
  DAILY_CREDITS = { "base" => 200, "premium" => 2_000 }.freeze

  has_many :personas, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :token_usages, dependent: :destroy
  has_many :received_invitations, class_name: "Invitation", foreign_key: :invitee_id, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :inviter_id, dependent: :destroy
  # Messages écrits dans les conversations des autres : ils restent, sans auteur
  has_many :messages, dependent: :nullify

  enum :status, { base: "base", premium: "premium", admin: "admin" }, default: "base", validate: true

  def unlimited_credits?
    admin?
  end

  def daily_credits
    DAILY_CREDITS[status] unless unlimited_credits?
  end

  def credits_used_today
    (token_usages.today.total_tokens / TOKENS_PER_CREDIT.to_f).ceil
  end

  def credits_left_today
    [daily_credits - credits_used_today, 0].max unless unlimited_credits?
  end

  def out_of_credits?
    !unlimited_credits? && credits_left_today.zero?
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  validates :username, presence: true, uniqueness: true
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
