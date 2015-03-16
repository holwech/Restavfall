json.array!(@events) do |event|
  json.extract! event, :id, :name, :eventId, :ukaURL
  json.url event_url(event, format: :json)
end
