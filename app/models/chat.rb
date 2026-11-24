class Chat < ApplicationRecord
  SUGGESTIONS_COUNT = 3

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

  # Demande à l'IA quelques messages que l'utilisateur pourrait envoyer ensuite,
  # selon l'état de la conversation, et les enregistre.
  # Un échec ici ne doit jamais casser le chat : on vide simplement la liste.
  def refresh_suggestions!
    # L'IA répond un message par ligne
    text = new_llm.with_instructions(suggestions_instructions).ask(recent_messages_as_text).content
    list = text.lines.map { |line| clean_suggestion(line) }.reject(&:blank?)
    update!(suggestions: list.first(SUGGESTIONS_COUNT))
  rescue RubyLLM::Error => e
    Rails.logger.warn("Suggestions failed for chat #{id}: #{e.message}")
    update!(suggestions: [])
  end

  private

  def suggestions_instructions
    <<~PROMPT
      You help a user chat with a character called "#{persona.name}".
      Character description: #{persona.description.presence || 'none'}.
      Character instructions: #{persona.system_prompt}

      Propose exactly #{SUGGESTIONS_COUNT} short messages (max 20 words each) that the USER
      could send next. Write them in the user's voice, addressed to #{persona.name}.

      They must build on what has already been said and move the conversation forward.
      Never repeat a question that was already asked. Make them varied:
      1. one that digs deeper into the last thing #{persona.name} said,
      2. one that opens a new but related angle,
      3. one that is more personal, playful or challenging.

      Always write the suggestions in English, whatever the language of the conversation.
      Answer with exactly #{SUGGESTIONS_COUNT} lines, one message per line,
      no numbering, no quotes, no speaker label (never start with "User:"), nothing else.
    PROMPT
  end

  # L'IA imite parfois le format de la conversation ("User: ...") ou ajoute
  # une numérotation / des guillemets : on retire tout ça.
  def clean_suggestion(line)
    labels = ["User", "You", "Me", persona.name].map { |label| Regexp.escape(label) }.join("|")
    line.strip
        .sub(/\A(\d+[.)]|[-*•])\s*/, "")              # "1. " / "- "
        .delete_prefix('"').delete_suffix('"')
        .sub(/\A\**(#{labels})\**\s*:\s*/i, "")       # "User: " / "**Einstein**: "
        .delete_prefix('"').delete_suffix('"')
        .strip
  end

  # Les 12 derniers messages en texte, un par paragraphe : "User: ..." / "Einstein: ..."
  def recent_messages_as_text
    messages.last(12).map { |message| "#{author_name(message)}: #{message.content}" }.join("\n\n")
  end

  def author_name(message)
    message.role == "user" ? "User" : persona.name
  end

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
