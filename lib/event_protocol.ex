defprotocol Irateburgers.EventProtocol do
  @dialyzer {:nowarn_function, __protocol__: 1}
  
  @doc "Apply an event to an aggregate"
  @spec apply(Irateburgers.EventProtocol.t, map) :: map
  def apply(event, aggregate)

  @doc "Convert an event struct to the generic event log storage representation"
  @spec to_event_log(Irateburgers.EventProtocol.t) :: Irateburgers.Event.t
  def to_event_log(event)
end
