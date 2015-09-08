class CreateUkeEvents < ActiveRecord::Migration
  def change
    create_table :uke_events do |t|
      t.string :title
      t.string :image
      t.boolean :auto_generated
    end
  end
end
