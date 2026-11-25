require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "owner@example.com", password: "password123", username: "owner")
    @guest = User.create!(email: "guest@example.com", password: "password123", username: "guest")
    persona = @owner.personas.create!(name: "Sherlock Holmes", system_prompt: "You are Sherlock.", built_in: true)
    @chat = @owner.chats.create!(persona: persona)
  end

  test "a new invitation is pending" do
    invitation = @chat.invitations.create!(inviter: @owner, invitee: @guest)

    assert_equal "pending", invitation.status
  end

  test "the owner cannot be invited to their own chat" do
    invitation = @chat.invitations.new(inviter: @owner, invitee: @owner)

    assert_not invitation.valid?
    assert_includes invitation.errors[:invitee], "already owns this chat"
  end

  test "the same person cannot be invited twice to a chat" do
    @chat.invitations.create!(inviter: @owner, invitee: @guest)

    assert_not @chat.invitations.new(inviter: @owner, invitee: @guest).valid?
  end

  test "a chat is accessible to its owner and to members who accepted, not to pending guests" do
    invitation = @chat.invitations.create!(inviter: @owner, invitee: @guest)

    assert_includes Chat.accessible_by(@owner), @chat
    assert_not_includes Chat.accessible_by(@guest), @chat

    invitation.update!(status: "accepted")
    assert_includes Chat.accessible_by(@guest), @chat
    assert_equal [@guest], @chat.members.to_a
  end

  test "in a shared chat, the author of the message pays for the reply and the suggestions" do
    @chat.invitations.create!(inviter: @owner, invitee: @guest, status: "accepted")
    message = @chat.messages.create!(role: "user", content: "Hi!", user: @guest)
    payers = []
    @chat.define_singleton_method(:new_llm) do |payer = user|
      payers << payer
      FakeLlm.new
    end

    ChatReplyJob.perform_now(message)

    assert_equal [@guest, @guest], payers
  end

  test "the tokens of an AI call are counted for the payer, not the owner" do
    response = Struct.new(:role, :tokens).new(:assistant, Struct.new(:input, :output).new(300, 200))

    @chat.send(:record_token_usage, response, @guest)

    assert_equal 500, @guest.token_usages.total_tokens
    assert_equal 0, @owner.token_usages.total_tokens
  end

  test "deleting a user who invited and wrote in someone else's chat keeps the chat" do
    other = User.create!(email: "other@example.com", password: "password123", username: "other")
    @chat.invitations.create!(inviter: @owner, invitee: @guest, status: "accepted")
    @chat.invitations.create!(inviter: @guest, invitee: other)
    message = @chat.messages.create!(role: "user", content: "Hi!", user: @guest)

    @guest.destroy!

    assert_nil message.reload.user
    assert_equal 0, @chat.invitations.count
  end
end
