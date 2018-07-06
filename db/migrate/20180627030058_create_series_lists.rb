class CreateSeriesLists < ActiveRecord::Migration[5.0]
  def change
    create_table :series_lists do |t|
      t.string :sn
      t.integer :batch_id

      t.timestamps
    end
  end
end
