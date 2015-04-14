json.array!(@events) do |event|
  json.extract! event, :id, :name, :url, :time, :fbpageID, :fbeventID
  json.url event_url(event, format: :json)
end
