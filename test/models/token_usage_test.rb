require "test_helper"

class TokenUsageTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "each AI call sends the credits left to the user's pages" do
    user = User.create!(email: "live@example.com", password: "password123", username: "live")

    broadcast = capture_turbo_stream_broadcasts([user, :credits]) do
      user.token_usages.create!(input_tokens: 1_000, output_tokens: 0)
    end.sole

    assert_equal "replace", broadcast["action"]
    assert_equal "credits", broadcast["target"]
    assert_includes broadcast.to_html, "190 credits"
  end
end
