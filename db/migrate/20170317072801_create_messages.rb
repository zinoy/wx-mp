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
      t.string :url
      t.string :media_id
      t.string :thumb_media_id
      t.string :format
      t.float :longtitude
      t.float :latitude
      t.float :scale
      t.datetime :send_at
      t.string :params

      t.timestamps
    end
  end
end
