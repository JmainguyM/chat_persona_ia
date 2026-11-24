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
end
