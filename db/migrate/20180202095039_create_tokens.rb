class CreateTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :tokens do |t|
      t.string :token
      t.string :app_id
      t.datetime :expired

      t.timestamps
    end
  end
end
