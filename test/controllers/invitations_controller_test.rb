require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = User.create!(email: "owner@example.com", password: "password123", username: "owner")
    @guest = User.create!(email: "guest@example.com", password: "password123", username: "guest")
    persona = @owner.personas.create!(name: "Sherlock Holmes", system_prompt: "You are Sherlock.", built_in: true)
    @chat = @owner.chats.create!(persona: persona)
    @chat.messages.create!(role: "assistant", content: "Good evening.")
  end

  test "the owner invites a member by username" do
    sign_in @owner

    assert_difference -> { @chat.invitations.pending.count }, 1 do
      post chat_invitations_path(@chat), params: { username: " guest " }
    end
    assert_redirected_to chat_path(@chat)
    assert_equal "Invitation sent to guest.", flash[:notice]
  end

  test "inviting an unknown username shows an error" do
    sign_in @owner

    assert_no_difference -> { Invitation.count } do
      post chat_invitations_path(@chat), params: { username: "nobody" }
    end
    assert_equal "No member named \"nobody\".", flash[:alert]
  end

  test "a guest who declined can be invited again" do
    invitation = @chat.invitations.create!(inviter: @owner, invitee: @guest, status: "declined")
    sign_in @owner

    post chat_invitations_path(@chat), params: { username: "guest" }

    assert_equal "pending", invitation.reload.status
  end

  test "someone outside the chat cannot invite" do
    sign_in @guest

    post chat_invitations_path(@chat), params: { username: "owner" }
    assert_response :not_found
  end

  test "accepting opens the chat to the guest, who can then write in it" do
    invitation = @chat.invitations.create!(inviter: @owner, invitee: @guest)
    sign_in @guest

    patch accept_invitation_path(invitation)
    assert_redirected_to chat_path(@chat)

    get chat_path(@chat)
    assert_response :success

    post chat_messages_path(@chat), params: { message: { content: "Hello!" } }
    assert_equal @guest, @chat.messages.last.user
  end

  test "a guest cannot delete the chat they joined" do
    @chat.invitations.create!(inviter: @owner, invitee: @guest, status: "accepted")
    sign_in @guest

    assert_no_difference -> { Chat.count } do
      delete chat_path(@chat)
    end
    assert_response :not_found
  end

  test "declining keeps the chat closed" do
    invitation = @chat.invitations.create!(inviter: @owner, invitee: @guest)
    sign_in @guest

    patch decline_invitation_path(invitation)

    assert_redirected_to dashboard_path
    assert_equal "declined", invitation.reload.status
    assert_not_includes Chat.accessible_by(@guest), @chat
  end

  test "only the invitee can accept an invitation" do
    other = User.create!(email: "other@example.com", password: "password123", username: "other")
    invitation = @chat.invitations.create!(inviter: @owner, invitee: @guest)
    sign_in other

    patch accept_invitation_path(invitation)

    assert_response :not_found
    assert_equal "pending", invitation.reload.status
  end

  test "pending invitations are listed on the dashboard" do
    @chat.invitations.create!(inviter: @owner, invitee: @guest)
    sign_in @guest

    get dashboard_path

    assert_response :success
    assert_includes response.body, "invites you to chat with"
  end
end
