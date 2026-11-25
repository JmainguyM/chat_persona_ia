require "test_helper"

class UserStatusSecurityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "signing up as admin is ignored, the account is base" do
    post user_registration_path, params: { user: {
      email: "hacker@example.com", username: "hacker",
      password: "password123", password_confirmation: "password123",
      status: "admin"
    } }

    assert User.find_by!(email: "hacker@example.com").base?
  end

  test "a user cannot make themselves admin from the account form" do
    user = User.create!(email: "member@example.com", password: "password123", username: "member")
    sign_in user

    put user_registration_path, params: { user: {
      username: "member", current_password: "password123", status: "admin"
    } }

    assert user.reload.base?
  end
end
