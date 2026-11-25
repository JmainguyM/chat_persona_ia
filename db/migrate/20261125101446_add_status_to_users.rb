class AddStatusToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :status, :string, default: "base", null: false
  end
end
