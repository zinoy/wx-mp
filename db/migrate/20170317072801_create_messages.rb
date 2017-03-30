class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.string :title
      t.string :content
      t.string :from
      t.string :to
      t.string :msg_type
      t.string :user_id
      t.string :origin
      t.string :origin_id
      t.datetime :send_at
      t.string :params

      t.timestamps
    end
  end
end
