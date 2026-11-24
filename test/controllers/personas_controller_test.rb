require "test_helper"

class PersonasControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "owner@example.com", password: "password123", username: "owner")
    @other = User.create!(email: "other@example.com", password: "password123", username: "other")
    @persona = @user.personas.create!(name: "Ada Lovelace", system_prompt: "You are Ada.")
    sign_in @user
  end

  test "new renders the form" do
    get new_persona_path
    assert_response :success
    assert_select "form textarea[name='persona[system_prompt]']"
    assert_select ".persona-preview"
  end

  test "create a persona and go back to the dashboard" do
    assert_difference("@user.personas.count", 1) do
      post personas_path, params: { persona: { name: "Coach", system_prompt: "You are a coach." } }
    end
    assert_redirected_to dashboard_path(anchor: "my-personas")
  end

  test "create without system prompt re-renders the form" do
    assert_no_difference("Persona.count") do
      post personas_path, params: { persona: { name: "Coach", system_prompt: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "update keeps the saved name in the header when invalid" do
    patch persona_path(@persona), params: { persona: { name: "" } }
    assert_response :unprocessable_entity
    assert_select "h1", "Ada Lovelace"
  end

  test "cannot edit someone else's persona" do
    sign_in @other
    get edit_persona_path(@persona)
    assert_response :not_found
  end

  test "built-in personas cannot be edited or deleted, even by their owner" do
    sherlock = @user.personas.create!(name: "Sherlock Holmes", system_prompt: "You are Sherlock.", built_in: true)

    get edit_persona_path(sherlock)
    assert_response :not_found

    # Une réponse 404 réinitialise la session Devise en test : on se reconnecte avant chaque requête
    sign_in @user
    patch persona_path(sherlock), params: { persona: { name: "Hacked" } }
    assert_response :not_found
    assert_equal "Sherlock Holmes", sherlock.reload.name

    sign_in @user
    assert_no_difference("Persona.count") { delete persona_path(sherlock) }
    assert_response :not_found
  end

  test "built_in cannot be set through the form" do
    post personas_path, params: { persona: { name: "Fake", system_prompt: "You are fake.", built_in: true } }
    assert_not Persona.find_by!(name: "Fake").built_in?
  end

  test "dashboard lists built-in personas in Explore without an Edit link" do
    @user.personas.create!(name: "Sherlock Holmes", system_prompt: "You are Sherlock.", built_in: true)
    get dashboard_path
    assert_select "#my-personas h3", text: "Sherlock Holmes", count: 0
    assert_select "#explore h3", text: "Sherlock Holmes"
    assert_select "#explore .dash-persona-edit", count: 0
  end

  test "explore page is public and asks visitors to log in to chat" do
    sign_out @user
    @user.personas.create!(name: "Sherlock Holmes", system_prompt: "You are Sherlock.", built_in: true)

    get personas_path
    assert_response :success
    assert_select "#featured h3", text: "Sherlock Holmes"
    assert_select "#community h3", text: "Ada Lovelace"
    assert_select "a[href='#{new_user_session_path}']", text: /Log in to chat/
    assert_select "form[action^='/personas/'][action$='/chats']", count: 0
  end

  test "visitors come back to the explore page after logging in" do
    sign_out @user
    get personas_path
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
    assert_redirected_to personas_path
  end

  test "signed-in users can start a chat from the explore page, and edit only their own personas" do
    @other.personas.create!(name: "Coach", system_prompt: "You are a coach.")

    get personas_path
    assert_select "form[action='#{persona_chats_path(@persona)}'] button", text: /Chat/
    assert_select ".dash-persona-edit", count: 1
    assert_select "a.dash-persona-edit[href='#{edit_persona_path(@persona)}']"
  end

  test "creating a persona requires an account" do
    sign_out @user
    get new_persona_path
    assert_redirected_to new_user_session_path
  end
end
