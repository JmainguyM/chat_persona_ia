require "test_helper"

class ChatTest < ActiveSupport::TestCase
  setup do
    user = User.create!(email: "model@example.com", password: "password123", username: "model")
    persona = user.personas.create!(name: "Sherlock Holmes", system_prompt: "You are Sherlock.")
    @chat = user.chats.create!(persona: persona)
  end

  test "awaiting a reply while the greeting is not there yet" do
    assert @chat.awaiting_reply?
  end

  test "awaiting a reply after a user message, not after an assistant message" do
    @chat.messages.create!(role: "assistant", content: "Hello")
    assert_not @chat.awaiting_reply?

    @chat.messages.create!(role: "user", content: "Hi")
    assert @chat.reload.awaiting_reply?
  end

  test "stops waiting after the timeout, so the chat is never stuck" do
    @chat.messages.create!(role: "user", content: "Hi", created_at: (Chat::REPLY_TIMEOUT + 1.minute).ago)
    assert_not @chat.awaiting_reply?
  end
end
