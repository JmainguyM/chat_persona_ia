require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  setup do
    @user = User.create!(email: "sender@example.com", password: "password123", username: "sender")
    @persona = @user.personas.create!(name: "Sherlock Holmes", system_prompt: "You are Sherlock.", built_in: true)
    @chat = @user.chats.create!(persona: @persona)
    @chat.messages.create!(role: "assistant", content: "Good evening.")
    sign_in @user
  end

  test "sending a message answers immediately and asks the AI in the background" do
    assert_enqueued_with(job: ChatReplyJob) do
      post chat_messages_path(@chat), params: { message: { content: "Who am I?" } }, as: :turbo_stream
    end

    assert_response :success
    assert_equal "Who am I?", @chat.messages.last.content
    assert_equal "user", @chat.messages.last.role, "the AI reply is not generated during the request"
    assert_includes response.body, "is typing"
  end

  test "cannot send another message while the persona is answering" do
    @chat.messages.create!(role: "user", content: "First question")

    assert_no_enqueued_jobs do
      post chat_messages_path(@chat), params: { message: { content: "Second question" } }, as: :turbo_stream
    end
    assert_response :conflict
  end

  test "an empty message is rejected" do
    assert_no_enqueued_jobs do
      post chat_messages_path(@chat), params: { message: { content: "" } }
    end
    assert_response :unprocessable_entity
  end
end
