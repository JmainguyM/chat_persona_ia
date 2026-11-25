require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

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

  test "delete a conversation from the dashboard" do
    chat = @user.chats.create!(persona: @persona)
    chat.messages.create!(role: "user", content: "Hello")

    get dashboard_path
    assert_select "form[action='#{chat_path(chat)}'] button.chat-delete"

    assert_difference(["Chat.count", "Message.count"], -1) { delete chat_path(chat) }
    assert_redirected_to dashboard_path(anchor: "conversations")
  end

  test "cannot delete someone else's conversation" do
    other = User.create!(email: "other@example.com", password: "password123", username: "other")
    chat = other.chats.create!(persona: @persona)

    assert_no_difference("Chat.count") { delete chat_path(chat) }
    assert_response :not_found
  end

  test "delete a conversation from its own page" do
    chat = @user.chats.create!(persona: @persona)

    get chat_path(chat)
    assert_select ".chat-head form[action='#{chat_path(chat)}'] button.chat-delete"

    assert_difference("Chat.count", -1) { delete chat_path(chat) }
    assert_redirected_to dashboard_path(anchor: "conversations")
  end

  test "starting a chat opens the page right away and greets in the background" do
    assert_enqueued_with(job: ChatStartJob) { post persona_chats_path(@persona) }
    chat = @user.chats.last
    assert_redirected_to chat_path(chat)
    assert_empty chat.messages, "the greeting is not generated during the request"

    get chat_path(chat)
    assert_select "turbo-cable-stream-source"
    assert_select "#typing .chat-typing", text: /Ada Lovelace is typing/
  end

  test "cannot start a conversation without credits left" do
    @user.token_usages.create!(input_tokens: 20_000, output_tokens: 0)

    assert_no_difference("Chat.count") { post persona_chats_path(@persona) }
    assert_redirected_to dashboard_path
  end

  test "the navbar shows the credits left" do
    get dashboard_path
    assert_select ".fab-credits", text: "200 credits"

    @user.admin!
    get dashboard_path
    assert_select ".fab-credits", text: "Unlimited credits"
  end
end
