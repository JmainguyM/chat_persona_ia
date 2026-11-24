class AddSuggestionsToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :suggestions, :jsonb, default: [], null: false
  end
end
