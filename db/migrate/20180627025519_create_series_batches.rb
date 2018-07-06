class CreateSeriesBatches < ActiveRecord::Migration[5.0]
  def change
    create_table :series_batches do |t|
      t.string :summary

      t.timestamps
    end
  end
end
