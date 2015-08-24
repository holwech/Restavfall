class CreateUkeEvents < ActiveRecord::Migration
  def change
    create_table :uke_events do |t|
      t.string :event_type
      t.string :title
      t.text :text
      t.string :image
      t.string :age_limit
      t.string :slug

      t.timestamps null: false
    end
  end
end
