class AddAttributesToResults < ActiveRecord::Migration
  def change
    add_column :results, :userFName, :string
    add_column :results, :friendFName, :string
  end
end
