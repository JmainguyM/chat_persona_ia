class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :persona
  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  # Premier message de la conversation, écrit par l'IA dans la voix de la persona.
  # Si l'IA ne répond pas, on garde un message générique pour ne pas bloquer la création du chat.
  def greet!
    messages.create!(role: "assistant", content: ai_greeting.presence || generic_greeting)
  end

  # Sends the conversation to the AI and saves its reply as an "assistant" message.
  def reply_to(user_message)
    llm = new_llm
    llm.with_instructions(persona.system_prompt)

    # Previous messages, so the AI remembers the conversation
    messages.where.not(id: user_message.id).each do |message|
      llm.add_message(role: message.role.to_sym, content: message.content)
    end

    response = llm.ask(user_message.content)
    messages.create!(role: "assistant", content: response.content)
  end

  private

  # Nouvelle conversation IA qui utilise explicitement la clé OPENAI_API_KEY (chargée depuis .env).
  # ENV.fetch lève une erreur claire si la clé est absente.
  def new_llm
    context = RubyLLM.context do |config|
      config.openai_api_key = ENV.fetch("OPENAI_API_KEY")
    end
    context.chat(model: "gpt-4o-mini")
  end

  def ai_greeting
    llm = new_llm
    llm.with_instructions(persona.system_prompt)
    llm.ask(
      "Start the conversation: greet the user in one or two short sentences, in character, " \
      "and invite them to talk. Always write in English."
    ).content
  rescue RubyLLM::Error => e
    Rails.logger.warn("Greeting failed for chat #{id}: #{e.message}")
    nil
  end

  def generic_greeting
    "Hello, I'm #{persona.name}. What would you like to talk about?"
  end
end
