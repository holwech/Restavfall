class CreateResults < ActiveRecord::Migration
  def change
    create_table :results do |t|
      t.string :userName
      t.string :userImg
      t.string :friendName
      t.string :friendImg
      t.integer :eventId

      t.timestamps null: false
    end
  end
end
