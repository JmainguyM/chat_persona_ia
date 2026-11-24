require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "home@example.com", password: "password123", username: "home")
    @sherlock = @user.personas.create!(name: "Sherlock Holmes", description: "Detective.", system_prompt: "x", built_in: true)
  end

  test "homepage cards show the built-in personas and send visitors to log in" do
    get root_path
    assert_response :success
    assert_select ".home-persona h3", text: "Sherlock Holmes"
    assert_select ".home-persona a.stretched-link[href='#{new_user_session_path}']"
  end

  test "visitors land on the explore page after logging in from the homepage" do
    get root_path
    post user_session_path, params: { user: { email: @user.email, password: "password123" } }
    assert_redirected_to personas_path
  end

  test "clicking a homepage card opens a conversation when signed in" do
    sign_in @user
    get root_path
    assert_select ".home-persona form[action='#{persona_chats_path(@sherlock)}'] button.stretched-link"
  end

  test "dashboard persona cards open a conversation" do
    sign_in @user
    get dashboard_path
    assert_select "#explore form[action='#{persona_chats_path(@sherlock)}'] button.stretched-link"
  end
end
