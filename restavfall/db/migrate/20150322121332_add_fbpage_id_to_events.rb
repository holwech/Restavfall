class AddFbpageIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :fbpageID, :string
  end
end
