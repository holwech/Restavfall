class CreateUkeShowings < ActiveRecord::Migration
  def change
    create_table :uke_showings do |t|
      t.integer :uke_event_id
      t.string :status
      t.boolean :tickets_available
      t.integer :price
      t.boolean :sale_open
      t.boolean :free
      t.boolean :canceled
      t.datetime :date
      t.datetime :sale_to
      t.datetime :sale_from
      t.string :title
      t.string :url
      t.boolean :sale_over
      t.string :place

      t.timestamps null: false
    end
  end
end
