class CreateUkeFbEvents < ActiveRecord::Migration
  def change
    create_table :uke_fb_events do |t|
      t.integer :uke_event_id
      t.string :fb_event_id
      t.boolean :auto_generated

      t.timestamps null: false
    end
  end
end
