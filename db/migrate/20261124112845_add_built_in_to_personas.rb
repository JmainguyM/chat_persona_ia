class AddBuiltInToPersonas < ActiveRecord::Migration[8.1]
  # Personas de base livrés avec l'app (seeds) : visibles par tous, modifiables par personne
  BUILT_IN_NAMES = ["Sherlock Holmes", "Albert Einstein", "Marie Curie"].freeze

  def up
    add_column :personas, :built_in, :boolean, default: false, null: false

    # Marque les personas de base déjà en base (créés par le compte admin des seeds)
    execute <<~SQL
      UPDATE personas SET built_in = TRUE
      FROM users
      WHERE personas.user_id = users.id
        AND users.email = 'admin@chatpersona.dev'
        AND personas.name IN (#{BUILT_IN_NAMES.map { |name| connection.quote(name) }.join(', ')})
    SQL
  end

  def down
    remove_column :personas, :built_in
  end
end
