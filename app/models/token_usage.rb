class TokenUsage < ApplicationRecord
  belongs_to :user
  belongs_to :chat, optional: true

  scope :today, -> { where(created_at: Time.current.all_day) }

  after_create_commit :broadcast_credits_left

  def self.total_tokens
    sum("input_tokens + output_tokens")
  end

  private

  def broadcast_credits_left
    broadcast_replace_to [user, :credits], target: "credits", partial: "shared/credits", locals: { user: user }
  end
end
