class CreateEvents < ActiveRecord::Migration
  def change
    drop_table :events
    create_table :events do |t|
      t.string :name
      t.string :url
      t.datetime :time
      t.string :fbpageID
      t.string :keywords
      t.string :relatedPages

      t.timestamps null: false
    end
  end
end
