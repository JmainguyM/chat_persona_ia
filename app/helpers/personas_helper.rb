module PersonasHelper
  # Images fournies dans app/assets/images pour les personas des seeds, qui n'ont pas d'avatar_url
  DEFAULT_AVATARS = {
    "Sherlock Holmes" => "sherlock.jpg",
    "Albert Einstein" => "einstein.jpg",
    "Marie Curie" => "marie-curie.jpg"
  }.freeze

  # Avatar d'un persona : photo uploadée, sinon avatar_url, sinon l'image par défaut, sinon les initiales
  def persona_avatar(persona, css_class: nil)
    source = persona_avatar_source(persona)

    if source
      image_tag source, alt: persona.name, class: css_class, loading: "lazy"
    else
      initials = persona.name.split.first(2).map { |word| word[0] }.join.upcase
      tag.div(initials, class: [css_class, "persona-initials"], aria: { hidden: true })
    end
  end

  # Image à afficher : photo uploadée, sinon avatar_url, sinon l'image par défaut (nil => initiales)
  def persona_avatar_source(persona)
    return persona.photo if persona_photo_saved?(persona)

    persona.avatar_url.presence || DEFAULT_AVATARS[persona.name]
  end

  # Photo déjà enregistrée sur Cloudinary (pas juste choisie dans un formulaire renvoyé avec des erreurs)
  def persona_photo_saved?(persona)
    persona.photo.attached? && persona.photo.persisted?
  end
end
