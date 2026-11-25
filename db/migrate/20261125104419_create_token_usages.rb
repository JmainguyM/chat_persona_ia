class CreateTokenUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :token_usages do |t|
      t.references :user, null: false, foreign_key: true
      t.references :chat, foreign_key: true
      t.integer :input_tokens, default: 0, null: false
      t.integer :output_tokens, default: 0, null: false

      t.timestamps
    end
    add_index :token_usages, %i[user_id created_at]
  end
end
