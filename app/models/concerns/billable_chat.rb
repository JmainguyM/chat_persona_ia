# Appels à l'IA d'une conversation et décompte des crédits (voir TokenUsage, User#credits_left_today).
# Chaque appel est payé par un utilisateur, le "payer" : par défaut le propriétaire de la conversation,
# mais dans une conversation partagée, c'est l'auteur du message qui paie la réponse du persona.
module BillableChat
  extend ActiveSupport::Concern

  private

  # Nouvelle conversation IA qui utilise explicitement la clé OPENAI_API_KEY (chargée depuis .env).
  # ENV.fetch lève une erreur claire si la clé est absente.
  def new_llm(payer = user)
    context = RubyLLM.context do |config|
      config.openai_api_key = ENV.fetch("OPENAI_API_KEY")
    end
    context.chat(model: "gpt-4o-mini").after_message { |response| record_token_usage(response, payer) }
  end

  def record_token_usage(response, payer = user)
    return unless response.role == :assistant

    payer.token_usages.create!(
      chat: self,
      input_tokens: response.tokens.input.to_i,
      output_tokens: response.tokens.output.to_i
    )
  end
end
