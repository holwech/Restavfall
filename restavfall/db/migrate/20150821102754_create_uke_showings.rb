class CreateUkeShowings < ActiveRecord::Migration
  def change
    create_table :uke_showings do |t|
      t.string :title
      t.boolean :sold_out
      t.datetime :date
      t.string :url
      t.string :place
      t.boolean :auto_generated
    end
  end
end
