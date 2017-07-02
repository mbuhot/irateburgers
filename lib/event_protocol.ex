defprotocol Irateburgers.EventProtocol do
  @doc "Apply an event to an aggregate"
  def apply(event, aggregate)

  @doc "Convert an event struct to the generic event log storage representation"
  def to_event_log(event)
end
