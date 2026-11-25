class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.references :chat, null: false, foreign_key: true
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.references :invitee, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    add_index :invitations, %i[chat_id invitee_id], unique: true

    # null pour les messages du persona
    add_reference :messages, :user, foreign_key: true
  end
end
