class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :name
      t.string :url
      t.datetime :time
      t.string :fbpageID
      t.string :fbeventID

      t.timestamps null: false
    end
  end
end
