ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Les tests n'appellent jamais OpenAI (pas de clé en CI, lent, payant, réponses imprévisibles).
# Chat#new_llm renvoie à la place ce faux client, qui répond toujours FakeLlm::REPLY.
class FakeLlm
  REPLY = "Fake AI reply\nSecond line\nThird line".freeze
  Response = Struct.new(:content)

  def with_instructions(*) = self
  def add_message(**) = self
  def ask(*) = Response.new(REPLY)
end

Chat.prepend(Module.new do
  private

  def new_llm = FakeLlm.new
end)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
