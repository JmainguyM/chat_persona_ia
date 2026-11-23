class CreatePersonas < ActiveRecord::Migration[8.1]
  def change
    create_table :personas do |t|
      t.string :name
      t.text :description
      t.text :system_prompt
      t.string :avatar_url
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
