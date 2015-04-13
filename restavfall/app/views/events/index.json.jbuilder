json.array!(@events) do |event|
  json.extract! event, :id, :id, :name, :url, :time, :fbpageID, :keywords, :relatedPages
  json.url event_url(event, format: :json)
end
