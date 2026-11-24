class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :persona
  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  # Sends the conversation to the AI and saves its reply as an "assistant" message.
  def reply_to(user_message)
    llm = RubyLLM.chat(model: "gpt-4o-mini")
    llm.with_instructions(persona.system_prompt)

    # Previous messages, so the AI remembers the conversation
    messages.where.not(id: user_message.id).each do |message|
      llm.add_message(role: message.role.to_sym, content: message.content)
    end

    response = llm.ask(user_message.content)
    messages.create!(role: "assistant", content: response.content)
  end
end
