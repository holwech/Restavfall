class CreateUkeEventData < ActiveRecord::Migration
  def change
    create_table :uke_event_data do |t|
      t.integer :uke_event_id
      t.text :description
    end
  end
end
