class CreateFollowers < ActiveRecord::Migration[5.0]
  def change
    create_table :followers do |t|
      t.string :user_id
      t.string :name
      t.string :avatar_url
      t.string :origin
      t.string :location
      t.string :gender
      t.integer :status

      t.timestamps
    end
  end
end
