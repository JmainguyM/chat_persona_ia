require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "credits@example.com", password: "password123", username: "credits")
  end

  def use_tokens(count, at: Time.current)
    @user.token_usages.create!(input_tokens: count, output_tokens: 0, created_at: at)
  end

  test "a new user is base with the base daily credits" do
    assert @user.base?
    assert_equal 200, @user.daily_credits
    assert_equal 200, @user.credits_left_today
  end

  test "premium users get more daily credits" do
    @user.premium!
    assert_equal 2_000, @user.daily_credits
  end

  test "an unknown status is rejected" do
    @user.status = "superadmin"
    assert_not @user.valid?
  end

  test "any started credit is spent" do
    use_tokens(30)
    assert_equal 1, @user.credits_used_today
    assert_equal 199, @user.credits_left_today
  end

  test "out of credits once the daily tokens are used, never below zero" do
    use_tokens(25_000)
    assert_equal 0, @user.credits_left_today
    assert @user.out_of_credits?
  end

  test "credits come back the next day" do
    use_tokens(20_000, at: 1.day.ago)
    assert_equal 200, @user.credits_left_today
  end

  test "admins have unlimited credits" do
    @user.admin!
    use_tokens(1_000_000)
    assert @user.unlimited_credits?
    assert_not @user.out_of_credits?
  end

  test "deleting a chat does not give credits back" do
    persona = @user.personas.create!(name: "Sherlock Holmes", system_prompt: "You are Sherlock.")
    chat = @user.chats.create!(persona: persona)
    @user.token_usages.create!(chat: chat, input_tokens: 20_000, output_tokens: 0)

    chat.destroy
    assert @user.out_of_credits?
  end
end
