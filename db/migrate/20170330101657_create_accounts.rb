class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.string :origin_id
      t.string :app_id
      t.string :app_secret
      t.string :token
      t.string :aes_key
      t.boolean :enabled, default: false
      t.boolean :verified, default: false

      t.timestamps
    end
  end
end
