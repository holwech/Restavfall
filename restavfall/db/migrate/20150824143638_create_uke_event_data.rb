class CreateUkeEventData < ActiveRecord::Migration
  def change
    create_table :uke_event_data do |t|
      t.string :uke_event_title
      t.text :description
    end
  end
end
