require "test_helper"

class PersonaTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "creator@example.com", password: "password123", username: "creator")
  end

  test "a user's persona needs a name" do
    persona = @user.personas.new(system_prompt: "You are a coach.", avatar_url: "https://example.com/coach.jpg")

    assert_not persona.valid?
    assert persona.errors.added?(:name, :blank)
  end

  test "a user's persona needs an image: a link or an uploaded photo" do
    persona = @user.personas.new(name: "Coach", system_prompt: "You are a coach.")
    assert_not persona.valid?
    assert_includes persona.errors[:avatar_url], "can't be blank: paste a link or upload a photo"

    persona.avatar_url = "https://example.com/coach.jpg"
    assert persona.valid?

    persona.avatar_url = nil
    persona.photo.attach(io: StringIO.new("fake image"), filename: "coach.png", content_type: "image/png")
    assert persona.valid?
  end

  test "built-in personas use their default image and need none" do
    assert @user.personas.new(name: "Sherlock Holmes", system_prompt: "You are Sherlock.", built_in: true).valid?
  end
end
