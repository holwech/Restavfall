class FixColumnName < ActiveRecord::Migration
  def change
  	rename_column :events, :ukaURL, :url
  	rename_column :events, :eventId, :eventID
  end
end
