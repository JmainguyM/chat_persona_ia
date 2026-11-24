require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "chatter@example.com", password: "password123", username: "chatter")
    @persona = @user.personas.create!(name: "Ada Lovelace", system_prompt: "You are Ada.", built_in: true)
    sign_in @user
  end

  test "Chat button on the dashboard starts a conversation" do
    get dashboard_path
    assert_select "form[action='#{persona_chats_path(@persona)}'] button", text: /Chat/

    assert_difference("@user.chats.count", 1) { post persona_chats_path(@persona) }
    assert_redirected_to chat_path(@user.chats.last)
  end

  test "an empty conversation is reused instead of creating a new one" do
    post persona_chats_path(@persona)
    assert_no_difference("Chat.count") { post persona_chats_path(@persona) }
  end

  test "a new conversation is created once the previous one has messages" do
    chat = @user.chats.create!(persona: @persona)
    chat.messages.create!(role: "user", content: "Hello")
    assert_difference("Chat.count", 1) { post persona_chats_path(@persona) }
  end

  test "dashboard lists conversations with messages, most recent first" do
    old_chat = @user.chats.create!(persona: @persona)
    old_chat.messages.create!(role: "user", content: "Old question")
    recent_chat = @user.chats.create!(persona: @persona)
    recent_chat.messages.create!(role: "assistant", content: "Recent answer")
    @user.chats.create!(persona: @persona) # vide : pas listée

    get dashboard_path
    assert_select ".dash-chat", count: 2
    assert_select ".dash-chat:first-child p", text: /Recent answer/
    assert_select ".dash-chat:last-child .dash-chat-you", text: "You:"
  end

  test "cannot open someone else's conversation" do
    other = User.create!(email: "other@example.com", password: "password123", username: "other")
    chat = other.chats.create!(persona: @persona)
    get chat_path(chat)
    assert_response :not_found
  end
end
