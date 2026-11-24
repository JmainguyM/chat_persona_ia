require "test_helper"
require "turbo/broadcastable/test_helper"

class ChatJobsTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    user = User.create!(email: "jobs@example.com", password: "password123", username: "jobs")
    @persona = user.personas.create!(name: "Sherlock Holmes", system_prompt: "You are Sherlock.", built_in: true)
    @chat = user.chats.create!(persona: @persona)
  end

  test "ChatStartJob writes the greeting and the suggestions" do
    ChatStartJob.perform_now(@chat)

    assert_equal ["assistant"], @chat.messages.pluck(:role)
    assert_equal FakeLlm::REPLY.lines.map(&:strip), @chat.reload.suggestions
  end

  test "ChatReplyJob answers the user's message and refreshes the suggestions" do
    question = @chat.messages.create!(role: "user", content: "Who am I?")

    ChatReplyJob.perform_now(question)

    assert_equal %w[user assistant], @chat.messages.pluck(:role)
    assert_equal FakeLlm::REPLY, @chat.messages.last.content
    assert_equal 3, @chat.reload.suggestions.size
  end

  test "ChatReplyJob tells the page when the AI fails" do
    question = @chat.messages.create!(role: "user", content: "Who am I?")
    # Simule une panne d'OpenAI pour cette conversation uniquement
    question.chat.define_singleton_method(:reply_to) { |_message| raise RubyLLM::Error, "OpenAI is down" }

    assert_turbo_stream_broadcasts @chat, count: 1 do
      ChatReplyJob.perform_now(question)
    end
    assert_equal ["user"], @chat.messages.pluck(:role)
  end

  test "ChatReplyJob is dropped when the conversation was deleted" do
    question = @chat.messages.create!(role: "user", content: "Who am I?")
    ChatReplyJob.perform_later(question)
    @chat.destroy

    assert_nothing_raised { perform_enqueued_jobs }
  end

  test "a new message is broadcast to the chat page" do
    assert_turbo_stream_broadcasts @chat, count: 3 do
      @chat.messages.create!(role: "user", content: "Hello") # message + typing + suggestions vidées
    end
  end
end
