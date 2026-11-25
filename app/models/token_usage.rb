class TokenUsage < ApplicationRecord
  belongs_to :user
  belongs_to :chat, optional: true

  scope :today, -> { where(created_at: Time.current.all_day) }

  def self.total_tokens
    sum("input_tokens + output_tokens")
  end
end
