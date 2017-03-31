class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :name
      t.string :origin_id
      t.string :app_id
      t.string :app_secret
      t.string :token
      t.string :aes_key
      t.string :welcome_msg
      t.boolean :enabled, default: false
      t.boolean :verified, default: false

      t.timestamps
    end
    
    add_index :accounts, :origin_id, unique: true
  end
end
